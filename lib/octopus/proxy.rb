require 'set'
require 'octopus/slave_group'
require 'octopus/load_balancing/round_robin'

module Octopus
  class Proxy
    attr_accessor :config, :sharded

    def initialize(config = Octopus.config)
      initialize_shards(config)
      initialize_replication(config) if !config.nil? && config['replicated']
    end

    def initialize_shards(config)
      @shards = HashWithIndifferentAccess.new
      @shards_slave_groups = HashWithIndifferentAccess.new
      @slave_groups = HashWithIndifferentAccess.new
      @groups = {}
      @adapters = Set.new
      @config = ActiveRecord::Base.connection_pool_without_octopus.spec.config

      unless config.nil?
        @entire_sharded = config['entire_sharded']
        @shards_config = config[Octopus.rails_env]
      end

      @shards_config ||= []

      @shards_config.each do |key, value|
        if value.is_a?(String)
          value = resolve_string_connection(value).merge(:octopus_shard => key)
          initialize_adapter(value['adapter'])
          @shards[key.to_sym] = connection_pool_for(value, "#{value['adapter']}_connection")
        elsif value.is_a?(Hash) && value.key?('adapter')
          value.merge!(:octopus_shard => key)
          initialize_adapter(value['adapter'])
          @shards[key.to_sym] = connection_pool_for(value, "#{value['adapter']}_connection")

          slave_group_configs = value.select do |_k, v|
            structurally_slave_group? v
          end

          if slave_group_configs.present?
            slave_groups = HashWithIndifferentAccess.new
            slave_group_configs.each do |slave_group_name, slave_configs|
              slaves = HashWithIndifferentAccess.new
              slave_configs.each do |slave_name, slave_config|
                @shards[slave_name.to_sym] = connection_pool_for(slave_config, "#{value['adapter']}_connection")
                slaves[slave_name.to_sym] = slave_name.to_sym
              end
              slave_groups[slave_group_name.to_sym] = Octopus::SlaveGroup.new(slaves)
            end
            @shards_slave_groups[key.to_sym] = slave_groups
            @sharded = true
          end
        elsif value.is_a?(Hash)
          @groups[key.to_s] = []

          value.each do |k, v|
            fail 'You have duplicated shard names!' if @shards.key?(k.to_sym)

            initialize_adapter(v['adapter'])
            config_with_octopus_shard = v.merge(:octopus_shard => k)

            @shards[k.to_sym] = connection_pool_for(config_with_octopus_shard, "#{v['adapter']}_connection")
            @groups[key.to_s] << k.to_sym
          end

          if structurally_slave_group? value
            slaves = Hash[@groups[key.to_s].map { |v| [v, v] }]
            @slave_groups[key.to_sym] = Octopus::SlaveGroup.new(slaves)
          end
        end
      end

      @shards[:master] ||= ActiveRecord::Base.connection_pool_without_octopus
    end

    def initialize_replication(config)
      @replicated = true
      if config.key?('fully_replicated')
        @fully_replicated = config['fully_replicated']
      else
        @fully_replicated = true
      end

      @slaves_list = @shards.keys.map(&:to_s).sort
      @slaves_list.delete('master')
      @slaves_load_balancer = Octopus::LoadBalancing::RoundRobin.new(@slaves_list)
    end

    def current_model
      Thread.current['octopus.current_model']
    end

    def current_model=(model)
      Thread.current['octopus.current_model'] = model.is_a?(ActiveRecord::Base) ? model.class : model
    end

    def current_shard
      Thread.current['octopus.current_shard'] ||= :master
    end

    def current_shard=(shard_symbol)
      self.current_slave_group = nil
      if shard_symbol.is_a?(Array)
        shard_symbol.each { |symbol| fail "Nonexistent Shard Name: #{symbol}" if @shards[symbol].nil? }
      elsif shard_symbol.is_a?(Hash)
        hash = shard_symbol
        shard_symbol = hash[:shard]
        slave_group_symbol = hash[:slave_group]

        if shard_symbol.nil? && slave_group_symbol.nil?
          fail 'Neither shard or slave group must be specified'
        end

        if shard_symbol.present?
          fail "Nonexistent Shard Name: #{shard_symbol}" if @shards[shard_symbol].nil?
        end

        if slave_group_symbol.present?
          if (@shards_slave_groups.try(:[], shard_symbol).present? && @shards_slave_groups[shard_symbol][slave_group_symbol].nil?) ||
              (@shards_slave_groups.try(:[], shard_symbol).nil? && @slave_groups[slave_group_symbol].nil?)
            fail "Nonexistent Slave Group Name: #{slave_group_symbol} in shards config: #{@shards_config.inspect}"
          end
          self.current_slave_group = slave_group_symbol
        end
      else
        fail "Nonexistent Shard Name: #{shard_symbol}" if @shards[shard_symbol].nil?
      end

      Thread.current['octopus.current_shard'] = shard_symbol
    end

    def current_group
      Thread.current['octopus.current_group']
    end

    def current_group=(group_symbol)
      # TODO: Error message should include all groups if given more than one bad name.
      [group_symbol].flatten.compact.each do |group|
        fail "Nonexistent Group Name: #{group}" unless has_group?(group)
      end

      Thread.current['octopus.current_group'] = group_symbol
    end

    def current_slave_group
      Thread.current['octopus.current_slave_group']
    end

    def current_slave_group=(slave_group_symbol)
      Thread.current['octopus.current_slave_group'] = slave_group_symbol
    end

    def block
      Thread.current['octopus.block']
    end

    def block=(block)
      Thread.current['octopus.block'] = block
    end

    def last_current_shard
      Thread.current['octopus.last_current_shard']
    end

    def last_current_shard=(last_current_shard)
      Thread.current['octopus.last_current_shard'] = last_current_shard
    end

    def fully_replicated?
      @fully_replicated || Thread.current['octopus.fully_replicated']
    end

    # Public: Whether or not a group exists with the given name converted to a
    # string.
    #
    # Returns a boolean.
    def has_group?(group)
      @groups.key?(group.to_s)
    end

    # Public: Retrieves names of all loaded shards.
    #
    # Returns an array of shard names as symbols
    def shard_names
      @shards.keys
    end

    # Public: Retrieves the defined shards for a given group.
    #
    # Returns an array of shard names as symbols or nil if the group is not
    # defined.
    def shards_for_group(group)
      @groups.fetch(group.to_s, nil)
    end

    # Rails 3.1 sets automatic_reconnect to false when it removes
    # connection pool.  Octopus can potentially retain a reference to a closed
    # connection pool.  Previously, that would work since the pool would just
    # reconnect, but in Rails 3.1 the flag prevents this.
    def safe_connection(connection_pool)
      connection_pool.automatic_reconnect ||= true
      if !connection_pool.connected? && @shards[:master].connection.query_cache_enabled
        connection_pool.connection.enable_query_cache!
      end
      connection_pool.connection
    end

    def select_connection
      safe_connection(@shards[shard_name])
    end

    def shard_name
      current_shard.is_a?(Array) ? current_shard.first : current_shard
    end

    def should_clean_table_name?
      @adapters.size > 1
    end

    def run_queries_on_shard(shard, &_block)
      keeping_connection_proxy(shard) do
        using_shard(shard) do
          yield
        end
      end
    end

    def send_queries_to_multiple_shards(shards, &block)
      shards.each do |shard|
        run_queries_on_shard(shard, &block)
      end
    end

    def clean_connection_proxy
      self.current_shard = :master
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
      if !sharded && current_model_replicated?
        run_queries_on_shard(:master) do
          select_connection.transaction(options, &block)
        end
      else
        select_connection.transaction(options, &block)
      end
    end

    def method_missing(method, *args, &block)
      if should_clean_connection_proxy?(method)
        conn = select_connection
        self.last_current_shard = current_shard
        clean_connection_proxy
        conn.send(method, *args, &block)
      elsif should_send_queries_to_shard_slave_group?(method)
        send_queries_to_shard_slave_group(method, *args, &block)
      elsif should_send_queries_to_slave_group?(method)
        send_queries_to_slave_group(method, *args, &block)
      elsif should_send_queries_to_replicated_databases?(method)
        send_queries_to_selected_slave(method, *args, &block)
      else
        select_connection.send(method, *args, &block)
      end
    end

    def respond_to?(method, include_private = false)
      super || select_connection.respond_to?(method, include_private)
    end

    def connection_pool
      @shards[current_shard]
    end

    def enable_query_cache!
      clear_query_cache
      with_each_healthy_shard { |v| v.connected? && safe_connection(v).enable_query_cache! }
    end

    def disable_query_cache!
      with_each_healthy_shard { |v| v.connected? && safe_connection(v).disable_query_cache! }
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
      @shards.any? { |_k, v| v.connected? }
    end

    def should_send_queries_to_shard_slave_group?(method)
      should_use_slaves_for_method?(method) && @shards_slave_groups.try(:[], current_shard).try(:[], current_slave_group).present?
    end

    def send_queries_to_shard_slave_group(method, *args, &block)
      send_queries_to_balancer(@shards_slave_groups[current_shard][current_slave_group], method, *args, &block)
    end

    def should_send_queries_to_slave_group?(method)
      should_use_slaves_for_method?(method) && @slave_groups.try(:[], current_slave_group).present?
    end

    def send_queries_to_slave_group(method, *args, &block)
      send_queries_to_balancer(@slave_groups[current_slave_group], method, *args, &block)
    end

    protected

    # Ensure that a single failing slave doesn't take down the entire application
    def with_each_healthy_shard
      @shards.each do |shard_name, v|
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

      conn_handler = ActiveRecord::Base.connection_handler
      if conn_handler.respond_to?(:connection_pool_list)
        # Rails 4+
        ar_pools = conn_handler.connection_pool_list
      else
        # Rails 3.2
        ar_pools = conn_handler.connection_pools.values
      end

      ar_pools.each do |pool|
        next if pool == @shards[:master] # Already handled this

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

    def connection_pool_for(adapter, config)
      if Octopus.rails4?
        arg = ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(adapter.dup, config)
      else
        arg = ActiveRecord::Base::ConnectionSpecification.new(adapter.dup, config)
      end

      ActiveRecord::ConnectionAdapters::ConnectionPool.new(arg)
    end

    def initialize_adapter(adapter)
      @adapters << adapter
      begin
        require "active_record/connection_adapters/#{adapter}_adapter"
      rescue LoadError
        raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$ERROR_INFO})"
      end
    end

    def resolve_string_connection(spec)
      if Octopus.rails41?
        resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new({})
        HashWithIndifferentAccess.new(resolver.spec(spec).config)
      else
        if Octopus.rails4?
          resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(spec, {})
        else
          resolver = ActiveRecord::Base::ConnectionSpecification::Resolver.new(spec, {})
        end
        HashWithIndifferentAccess.new(resolver.spec.config)
      end
    end

    def should_clean_connection_proxy?(method)
      method.to_s =~ /insert|select|execute/ && !current_model_replicated? && (!block || block != current_shard)
    end

    # Try to use slaves if and only if `replicated: true` is specified in `shards.yml` and no slaves groups are defined
    def should_send_queries_to_replicated_databases?(method)
      @replicated && method.to_s =~ /select/ && !block && !slaves_grouped?
    end

    def current_model_replicated?
      @replicated && (current_model.try(:replicated) || fully_replicated?)
    end

    def send_queries_to_selected_slave(method, *args, &block)
      if current_model.replicated || fully_replicated?
        selected_slave = @slaves_load_balancer.next
      else
        selected_slave = :master
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
      @slave_groups.present?
    end

    # Temporarily switch `current_shard` to the next slave in a slave group and send queries to it
    # while preserving `current_shard`
    def send_queries_to_balancer(balancer, method, *args, &block)
      send_queries_to_slave(balancer.next, method, *args, &block)
    end

    # Temporarily switch `current_shard` to the specified slave and send queries to it
    # while preserving `current_shard`
    def send_queries_to_slave(slave, method, *args, &block)
      using_shard(slave) do
        select_connection.send(method, *args, &block)
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

      begin
        unless current_model && !current_model.allowed_shard?(shard)
          self.current_shard = shard
        end
        yield
      ensure
        self.current_shard = older_shard
      end
    end

    def structurally_slave?(config)
      config.is_a?(Hash) && config.key?('adapter')
    end

    def structurally_slave_group?(config)
      config.is_a?(Hash) && config.values.any? { |v| structurally_slave? v }
    end
  end
end
