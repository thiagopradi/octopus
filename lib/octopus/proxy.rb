require 'set'
require 'octopus/slave_group'
require 'octopus/load_balancing/round_robin'

module Octopus
  class Proxy
    attr_accessor :proxy_config

    delegate :current_model, :current_model=,
             :current_shard, :current_shard=,
             :current_group, :current_group=,
             :current_slave_group, :current_slave_group=,
             :current_load_balance_options, :current_load_balance_options=,
             :block, :block=, :fully_replicated?, :has_group?,
             :shard_names, :shards_for_group, :shards, :sharded, :slaves_list,
             :shards_slave_groups, :slave_groups, :replicated, :slaves_load_balancer,
             :config, :initialize_shards, :shard_name, to: :proxy_config, prefix: false

    def initialize(config = Octopus.config)
      self.proxy_config = Octopus::ProxyConfig.new(config)
    end

    # Rails Connection Methods - Those methods are overriden to add custom behavior that helps
    # Octopus introduce Sharding / Replication.
    delegate :adapter_name, :add_transaction_record, :case_sensitive_modifier,
      :type_cast, :to_sql, :quote, :quote_column_name, :quote_table_name,
      :quote_table_name_for_assignment, :supports_migrations?, :table_alias_for,
      :table_exists?, :in_clause_length, :supports_ddl_transactions?,
      :sanitize_limit, :prefetch_primary_key?, :current_database, :initialize_schema_migrations_table,
      :combine_bind_parameters, :empty_insert_statement_value, :assume_migrated_upto_version,
      :schema_cache, :substitute_at, :internal_string_options_for_primary_key, :lookup_cast_type_from_column,
      :supports_advisory_locks?, :get_advisory_lock, :initialize_internal_metadata_table,
      :release_advisory_lock, :prepare_binds_for_database, :cacheable_query, :column_name_for_operation,
      :prepared_statements, :transaction_state, :create_table, to: :select_connection

    def execute(sql, name = nil)
      begin
        retries ||= 0
        conn = select_connection
        clean_connection_proxy if should_clean_connection_proxy?('execute')
        conn.execute(sql, name)
      rescue ActiveRecord::StatementInvalid => e
        if connection_bad(e.message)
          Octopus.logger.error "Octopus.logger.error execute: #{e.message}"
          conn.verify!
          retry if (retries += 1) < 3
        else
          raise e.message
        end
      end
    end

    def insert(arel, name = nil, pk = nil, id_value = nil, sequence_name = nil, binds = [])
      begin
        retries ||= 0
        conn = select_connection
        clean_connection_proxy if should_clean_connection_proxy?('insert')
        conn.insert(arel, name, pk, id_value, sequence_name, binds)
      rescue ActiveRecord::StatementInvalid => e
        if connection_bad(e.message)
          Octopus.logger.error "Octopus.logger.error insert: #{e.message}"
          conn.verify!
          retry if (retries += 1) < 3
        else
          raise e.message
        end
      end
    end

    def update(arel, name = nil, binds = [])
      begin
        retries ||= 0
        conn = select_connection
        # Call the legacy should_clean_connection_proxy? method here, emulating an insert.
        clean_connection_proxy if should_clean_connection_proxy?('insert')
        conn.update(arel, name, binds)
      rescue ActiveRecord::StatementInvalid => e
        if connection_bad(e.message)
          Octopus.logger.error "Octopus.logger.error update: #{e.message}"
          conn.verify!
          retry if (retries += 1) < 3
        else
          raise e.message
        end
      end
    end

    def delete(*args, &block)
      legacy_method_missing_logic('delete', *args, &block)
    end

    def select_all(*args, &block)
      legacy_method_missing_logic('select_all', *args, &block)
    end

    def select_value(*args, &block)
      legacy_method_missing_logic('select_value', *args, &block)
    end

    # Rails 3.1 sets automatic_reconnect to false when it removes
    # connection pool.  Octopus can potentially retain a reference to a closed
    # connection pool.  Previously, that would work since the pool would just
    # reconnect, but in Rails 3.1 the flag prevents this.
    def safe_connection(connection_pool)
      connection_pool.automatic_reconnect ||= true
      if !connection_pool.connected? && shards[Octopus.master_shard].connection.query_cache_enabled
        connection_pool.connection.enable_query_cache!
      end
      connection_pool.connection
    end

    def select_connection
      safe_connection(shards[shard_name])
    end

    def run_queries_on_shard(shard, &_block)
      keeping_connection_proxy(shard) do
        using_shard(shard) do
          yield
        end
      end
    end

    def send_queries_to_multiple_shards(shards, &block)
      shards.map do |shard|
        run_queries_on_shard(shard, &block)
      end
    end

    def send_queries_to_group(group, &block)
      using_group(group) do
        send_queries_to_multiple_shards(shards_for_group(group), &block)
      end
    end

    def send_queries_to_all_shards(&block)
      send_queries_to_multiple_shards(shard_names.uniq { |shard_name| shards[shard_name] }, &block)
    end

    def clean_connection_proxy
      self.current_shard = Octopus.master_shard
      self.current_model = nil
      self.current_group = nil
      self.block = nil
    end

    def check_schema_migrations(shard)
      OctopusModel.using(shard).connection.table_exists?(
        ActiveRecord::Migrator.schema_migrations_table_name,
      ) || OctopusModel.using(shard).connection.initialize_schema_migrations_table
    end

    def transaction(options = {}, &block)
      begin
        retries ||= 0
        if !sharded && current_model_replicated?
          run_queries_on_shard(Octopus.master_shard) do
            select_connection.transaction(options, &block)
          end
        else
          select_connection.transaction(options, &block)
        end
      rescue ActiveRecord::StatementInvalid => e
        if connection_bad(e.message)
          Octopus.logger.error "Octopus.logger.error transaction: #{e.message}"
          select_connection.verify!
          retry if (retries += 1) < 3
        else
          raise e.message
        end
      end
    end

    def method_missing(method, *args, &block)
      legacy_method_missing_logic(method, *args, &block)
    end

    def respond_to?(method, include_private = false)
      super || select_connection.respond_to?(method, include_private)
    end

    def connection_pool
      shards[current_shard]
    end

    if Octopus.rails4?
      def enable_query_cache!
        clear_query_cache
        with_each_healthy_shard { |v| v.connected? && safe_connection(v).enable_query_cache! }
      end

      def disable_query_cache!
        with_each_healthy_shard { |v| v.connected? && safe_connection(v).disable_query_cache! }
      end
    end

    def clear_query_cache
      with_each_healthy_shard { |v| v.connected? && safe_connection(v).clear_query_cache }
    end

    def clear_active_connections!
      with_each_healthy_shard(&:release_connection)
    end

    def clear_all_connections!
      with_each_healthy_shard(&:disconnect!)
    end

    def connected?
      shards.any? { |_k, v| v.connected? }
    end

    def should_send_queries_to_shard_slave_group?(method)
      should_use_slaves_for_method?(method) && shards_slave_groups.try(:[], current_shard).try(:[], current_slave_group).present?
    end

    def send_queries_to_shard_slave_group(method, *args, &block)
      send_queries_to_balancer(shards_slave_groups[current_shard][current_slave_group], method, *args, &block)
    end

    def should_send_queries_to_slave_group?(method)
      should_use_slaves_for_method?(method) && slave_groups.try(:[], current_slave_group).present?
    end

    def send_queries_to_slave_group(method, *args, &block)
      send_queries_to_balancer(slave_groups[current_slave_group], method, *args, &block)
    end

    def current_model_replicated?
      replicated && (current_model.try(:replicated) || fully_replicated?)
    end

    protected

    def connection_bad(error)
      error.include? "PG::ConnectionBad"
    end

    # @thiagopradi - This legacy method missing logic will be keep for a while for compatibility
    # and will be removed when Octopus 1.0 will be released.
    # We are planning to migrate to a much stable logic for the Proxy that doesn't require method missing.
    def legacy_method_missing_logic(method, *args, &block)
      begin
        retries ||= 0
        if should_clean_connection_proxy?(method)
          conn = select_connection
          clean_connection_proxy
          conn.send(method, *args, &block)
        elsif should_send_queries_to_shard_slave_group?(method)
          send_queries_to_shard_slave_group(method, *args, &block)
        elsif should_send_queries_to_slave_group?(method)
          send_queries_to_slave_group(method, *args, &block)
        elsif should_send_queries_to_replicated_databases?(method)
          send_queries_to_selected_slave(method, *args, &block)
        else
          val = select_connection.send(method, *args, &block)

          if val.instance_of? ActiveRecord::Result
            val.current_shard = shard_name
          end

          val
        end
      rescue ActiveRecord::StatementInvalid => e
        if connection_bad(e.message)
          Octopus.logger.error "Octopus.logger.error legacy_method_missing_logic: #{e.message}"
          select_connection.verify!
          retry if (retries += 1) < 3
        else
          raise e.message
        end
      end
    end

    # Ensure that a single failing slave doesn't take down the entire application
    def with_each_healthy_shard
      shards.each do |shard_name, v|
        begin
          yield(v)
        rescue => e
          if Octopus.robust_environment?
            Octopus.logger.error "Error on shard #{shard_name}: #{e.message}"
          else
            raise
          end
        end
      end

      ar_pools = ActiveRecord::Base.connection_handler.connection_pool_list

      ar_pools.each do |pool|
        next if pool == shards[:master] # Already handled this

        begin
          yield(pool)
        rescue => e
          if Octopus.robust_environment?
            Octopus.logger.error "Error on pool (spec: #{pool.spec}): #{e.message}"
          else
            raise
          end
        end
      end
    end

    def should_clean_connection_proxy?(method)
      method.to_s =~ /insert|select|execute/ && !current_model_replicated? && (!block || block != current_shard)
    end

    # Try to use slaves if and only if `replicated: true` is specified in `shards.yml` and no slaves groups are defined
    def should_send_queries_to_replicated_databases?(method)
      replicated && method.to_s =~ /select/ && !block && !slaves_grouped?
    end

    def send_queries_to_selected_slave(method, *args, &block)
      if current_model.replicated || fully_replicated?
        selected_slave = slaves_load_balancer.next current_load_balance_options
      else
        selected_slave = Octopus.master_shard
      end

      send_queries_to_slave(selected_slave, method, *args, &block)
    end

    # We should use slaves if and only if its safe to do so.
    #
    # We can safely use slaves when:
    # (1) `replicated: true` is specified in `shards.yml`
    # (2) The current model is `replicated()`, or `fully_replicated: true` is specified in `shards.yml` which means that
    #     all the model is `replicated()`
    # (3) It's a SELECT query
    # while ensuring that we revert `current_shard` from the selected slave to the (shard's) master
    # not to make queries other than SELECT leak to the slave.
    def should_use_slaves_for_method?(method)
      current_model_replicated? && method.to_s =~ /select/
    end

    def slaves_grouped?
      slave_groups.present?
    end

    # Temporarily switch `current_shard` to the next slave in a slave group and send queries to it
    # while preserving `current_shard`
    def send_queries_to_balancer(balancer, method, *args, &block)
      send_queries_to_slave(balancer.next(current_load_balance_options), method, *args, &block)
    end

    # Temporarily switch `current_shard` to the specified slave and send queries to it
    # while preserving `current_shard`
    def send_queries_to_slave(slave, method, *args, &block)
      using_shard(slave) do
        val = select_connection.send(method, *args, &block)
        if val.instance_of? ActiveRecord::Result
          val.current_shard = slave
        end
        val
      end
    end

    # Temporarily block cleaning connection proxy and run the block
    #
    # @see Octopus::Proxy#should_clean_connection?
    # @see Octopus::Proxy#clean_connection_proxy
    def keeping_connection_proxy(shard, &_block)
      last_block = block

      begin
        self.block = shard
        yield
      ensure
        self.block = last_block || nil
      end
    end

    # Temporarily switch `current_shard` and run the block
    def using_shard(shard, &_block)
      older_shard = current_shard
      older_slave_group = current_slave_group
      older_load_balance_options = current_load_balance_options

      begin
        unless current_model && !current_model.allowed_shard?(shard)
          self.current_shard = shard
        end
        yield
      ensure
        self.current_shard = older_shard
        self.current_slave_group = older_slave_group
        self.current_load_balance_options = older_load_balance_options
      end
    end

    # Temporarily switch `current_group` and run the block
    def using_group(group, &_block)
      older_group = current_group

      begin
        self.current_group = group
        yield
      ensure
        self.current_group = older_group
      end
    end
  end
end
