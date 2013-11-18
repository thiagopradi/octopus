require "set"

class Octopus::Proxy
  attr_accessor :config

  def initialize(config = Octopus.config)
    initialize_shards(config)
    initialize_replication(config) if !config.nil? && config["replicated"]
  end

  def initialize_shards(config)
    @shards = HashWithIndifferentAccess.new
    @groups = {}
    @adapters = Set.new
    @shards[:master] = ActiveRecord::Base.connection_pool_without_octopus()
    @config = ActiveRecord::Base.connection_pool_without_octopus.connection.instance_variable_get(:@config)

    if !config.nil?
      @entire_sharded = config['entire_sharded']
      shards_config = config[Octopus.rails_env()]
    end

    shards_config ||= []

    shards_config.each do |key, value|
      if value.is_a?(String) 
        value = resolve_string_connection(value).merge(:octopus_shard => key)
        initialize_adapter(value['adapter'])
        @shards[key.to_sym] = connection_pool_for(value, "#{value['adapter']}_connection")
      elsif value.is_a?(Hash) && value.has_key?("adapter")
        value.merge!(:octopus_shard => key)
        initialize_adapter(value['adapter'])
        @shards[key.to_sym] = connection_pool_for(value, "#{value['adapter']}_connection")
      elsif value.is_a?(Hash)
        @groups[key.to_s] = []

        value.each do |k, v|
          raise "You have duplicated shard names!" if @shards.has_key?(k.to_sym)

          initialize_adapter(v['adapter'])
          config_with_octopus_shard = v.merge(:octopus_shard => k)

          @shards[k.to_sym] = connection_pool_for(config_with_octopus_shard, "#{v['adapter']}_connection")
          @groups[key.to_s] << k.to_sym
        end
      end
    end
  end

  def initialize_replication(config)
    @replicated = true
    if config.has_key?("fully_replicated")
      @fully_replicated = config["fully_replicated"]
    else
      @fully_replicated = true
    end

    @slaves_list = @shards.keys.map {|sym| sym.to_s}.sort
    @slaves_list.delete('master')
    @slave_index = 0
  end

  def current_model
    Thread.current["octopus.current_model"]
  end

  def current_model=(model)
    Thread.current["octopus.current_model"] = model.is_a?(ActiveRecord::Base) ? model.class : model
  end

  def current_shard
    Thread.current["octopus.current_shard"] ||= :master
  end

  def current_shard=(shard_symbol)
    if shard_symbol.is_a?(Array)
      shard_symbol.each {|symbol| raise "Nonexistent Shard Name: #{symbol}" if @shards[symbol].nil? }
    else
      raise "Nonexistent Shard Name: #{shard_symbol}" if @shards[shard_symbol].nil?
    end

    Thread.current["octopus.current_shard"] = shard_symbol
  end

  def current_group
    Thread.current["octopus.current_group"]
  end

  def current_group=(group_symbol)
    # TODO: Error message should include all groups if given more than one bad name.
    [group_symbol].flatten.compact.each do |group|
      raise "Nonexistent Group Name: #{group}" unless has_group?(group)
    end

    Thread.current["octopus.current_group"] = group_symbol
  end

  def block
    Thread.current["octopus.block"]
  end

  def block=(block)
    Thread.current["octopus.block"] = block
  end

  def last_current_shard
    Thread.current["octopus.last_current_shard"]
  end

  def last_current_shard=(last_current_shard)
    Thread.current["octopus.last_current_shard"] = last_current_shard
  end

  # Public: Whether or not a group exists with the given name converted to a
  # string.
  #
  # Returns a boolean.
  def has_group?(group)
    @groups.has_key?(group.to_s)
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
    connection_pool.connection()
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

  def run_queries_on_shard(shard, &block)
    older_shard = self.current_shard
    last_block = self.block

    begin
      self.block = true
      self.current_shard = shard
      yield
    ensure
      self.block = last_block || false
      self.current_shard = older_shard
    end
  end

  def send_queries_to_multiple_shards(shards, &block)
    shards.each do |shard|
      self.run_queries_on_shard(shard, &block)
    end
  end

  def clean_proxy()
    self.current_shard = :master
    self.current_group = nil
    self.block = false
  end

  def check_schema_migrations(shard)
    if !OctopusModel.using(shard).connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
      OctopusModel.using(shard).connection.initialize_schema_migrations_table
    end
  end

  def transaction(options = {}, &block)
    if @replicated && (current_model.replicated || @fully_replicated)
      self.run_queries_on_shard(:master) do
        select_connection.transaction(options, &block)
      end
    else
      select_connection.transaction(options, &block)
    end
  end

  def method_missing(method, *args, &block)
    if should_clean_connection?(method)
      conn = select_connection()
      self.last_current_shard = self.current_shard
      clean_proxy()
      conn.send(method, *args, &block)
    elsif should_send_queries_to_replicated_databases?(method)
      send_queries_to_selected_slave(method, *args, &block)
    else
      select_connection().send(method, *args, &block)
    end
  end

  def respond_to?(method, include_private = false)
    super || select_connection.respond_to?(method, include_private)
  end

  def connection_pool
    return @shards[current_shard]
  end

  def enable_query_cache!
    @shards.each do |k, v|
      c = safe_connection(v)
      c.clear_query_cache_without_octopus
      c.enable_query_cache!
    end
  end

  def disable_query_cache!
    @shards.each { |k, v| safe_connection(v).disable_query_cache! }
  end

  def clear_all_query_caches!
    @shards.each { |k, v| safe_connection(v).clear_query_cache_without_octopus }
  end

  def disconnect!
    @shards.each { |k, v| v.disconnect! }
  end

  protected

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
      raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
    end
  end

  def resolve_string_connection(spec)
    if Octopus.rails4?
      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(spec, {})
    else
      resolver = ActiveRecord::Base::ConnectionSpecification::Resolver.new(spec, {})
    end
    resolver.spec.config.stringify_keys
  end

  def should_clean_connection?(method)
    method.to_s =~ /insert|select|execute/ && !@replicated && !self.block
  end

  def should_send_queries_to_replicated_databases?(method)
    @replicated && method.to_s =~ /select/ && !self.block
  end

  def send_queries_to_selected_slave(method, *args, &block)
    old_shard = self.current_shard

    begin
      if current_model.replicated || @fully_replicated
        self.current_shard = @slaves_list[@slave_index = (@slave_index + 1) % @slaves_list.length]
      else
        self.current_shard = :master
      end

      select_connection.send(method, *args, &block)
    ensure
      self.current_shard = old_shard
    end
  end
end
