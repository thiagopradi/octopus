require "set"

class Octopus::Proxy
  attr_accessor :current_model, :current_shard, :current_group, :block,
      :using_enabled, :last_current_shard, :config, :write_occurred

  def initialize(config)
    initialize_shards(config)
    initialize_replication(config) if !config.nil? && config["replicated"]
  end

  def initialize_shards(config)
    @shards = HashWithIndifferentAccess.new
    @groups = HashWithIndifferentAccess.new
    @adapters = Set.new
    @shards[:master] = ActiveRecord::Base.connection_pool_without_octopus()
    @config = ActiveRecord::Base.connection_pool_without_octopus.connection.instance_variable_get(:@config)
    @current_shard = :master

    if !config.nil? && config.has_key?("verify_connection")
      @verify_connection = config["verify_connection"]
    else
      @verify_connection = false
    end

    if !config.nil?
      @entire_sharded = config['entire_sharded']
      shards_config = config[Octopus.rails_env()]
    end

    shards_config ||= []

    shards_config.each do |key, value|
      if value.has_key?("adapter")
        initialize_adapter(value['adapter'])
        @shards[key.to_sym] = connection_pool_for(value, "#{value['adapter']}_connection")
      else
        @groups[key.to_sym] = []

        value.each do |k, v|
          raise "You have duplicated shard names!" if @shards.has_key?(k.to_sym)
          initialize_adapter(v['adapter'])
          config_with_octopus_shard = v.merge(:octopus_shard => k)
          @shards[k.to_sym] = connection_pool_for(config_with_octopus_shard, "#{v['adapter']}_connection")
          @groups[key.to_sym] << k.to_sym
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

    if config.has_key?("read_from_master_following_write")
      @read_from_master_following_write = true
    else
      @read_from_master_following_write = false
    end

    @slaves_list = @shards.keys.map {|sym| sym.to_s}.sort
    @slaves_list.delete('master')
    @slave_index = 0
  end

  def current_shard=(shard_symbol)
    if shard_symbol.is_a?(Array)
      shard_symbol.each {|symbol| raise "Nonexistent Shard Name: #{symbol}" if @shards[symbol].nil? }
    else
      raise "Nonexistent Shard Name: #{shard_symbol}" if @shards[shard_symbol].nil?
    end

    @current_shard = shard_symbol
  end

  def current_group=(group_symbol)
    if group_symbol.is_a?(Array)
      group_symbol.each {|symbol| raise "Nonexistent Group Name: #{symbol}" if @groups[symbol].nil? }
    else
      raise "Nonexistent Group Name: #{group_symbol}" if @groups[group_symbol].nil?
    end

    @current_group = group_symbol
  end

  def current_model=(model)
    @current_model = model.is_a?(ActiveRecord::Base) ? model.class : model
  end

  def select_connection
    @shards[shard_name].verify_active_connections! if @verify_connection
    # Rails 3.1 sets automatic_reconnect to false when it removes
    # connection pool.  Octopus can potentially retain a reference to a closed
    # connection pool.  Previously, that would work since the pool would just
    # reconnect, but in Rails 3.1 the flag prevents this.
    if Octopus.rails31?
      if !@shards[shard_name].automatic_reconnect
        @shards[shard_name].automatic_reconnect = true
      end
    end

    @shards[shard_name].connection()
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
    @using_enabled = nil
    @current_shard = :master
    @current_group = nil
    @block = false
    @write_occurred = nil
  end

  def check_schema_migrations(shard)
    if !OctopusModel.using(shard).connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
      OctopusModel.using(shard).connection.initialize_schema_migrations_table
    end
  end

  def transaction(options = {}, &block)
    if @replicated && (current_model.read_inheritable_attribute(:replicated) || @fully_replicated)
      self.run_queries_on_shard(:master) do
        select_connection.transaction(options, &block)
      end
    else
      select_connection.transaction(options, &block)
    end
  end

  def method_missing(method, *args, &block)
    if !@write_occurred && should_clean_connection?(method)
      conn = select_connection()
      self.last_current_shard = self.current_shard
      clean_proxy()
      conn.send(method, *args, &block)
    elsif !@write_occurred && should_send_queries_to_replicated_databases?(method)
      send_queries_to_selected_slave(method, *args, &block)
    else
      @write_occurred ||= true if @read_from_master_following_write
      select_connection().send(method, *args, &block)
    end
  end

  def respond_to?(method, include_private = false)
    super || select_connection.respond_to?(method, include_private)
  end

  def connection_pool
    return @shards[current_shard]
  end

  protected
  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter.dup, config))
  end

  def initialize_adapter(adapter)
    @adapters << adapter
    begin
      require "active_record/connection_adapters/#{adapter}_adapter"
    rescue LoadError
      raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
    end
  end

  def should_clean_connection?(method)
    method.to_s =~ /insert|select|execute/ && !@replicated && !self.block
  end

  def should_send_queries_to_replicated_databases?(method)
    @replicated && method.to_s =~ /select/ && !@block
  end

  def send_queries_to_selected_slave(method, *args, &block)
    old_shard = self.current_shard

    begin
      if current_model.read_inheritable_attribute(:replicated) || @fully_replicated
        self.current_shard = @slaves_list[@slave_index = (@slave_index + 1) % @slaves_list.length]
      else
        self.current_shard = :master
      end

      sql = select_connection().send(method, *args, &block)
      return sql
    ensure
      self.current_shard = old_shard
      @using_enabled = nil
    end
  end
end
