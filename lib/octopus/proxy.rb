class Octopus::Proxy
  attr_accessor :current_model, :current_shard, :current_group, :block, :using_enabled, :last_current_shard

  def initialize(config)    
    initialize_shards(config)
    initialize_replication(config) if have_config_for_enviroment?(config) && config[Octopus.env()]["replicated"]
  end

  def initialize_shards(config)
    @shards = {}
    @groups = {}
    @shards[:master] = ActiveRecord::Base.connection_pool()
    @current_shard = :master
    
    if have_config_for_enviroment?(config) && Octopus.rails?
      shards_config = config[Octopus.env()][Rails.env().to_s]["shards"]
    elsif have_config_for_enviroment?(config)
      shards_config = config[Octopus.env()]["shards"]
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
          @shards[k.to_sym] = connection_pool_for(v, "#{v['adapter']}_connection")
          @groups[key.to_sym] << k.to_sym
        end
      end
    end
  end

  def initialize_replication(config)
    @replicated = true
    @entire_replicated = config[Octopus.env()]["entire_replicated"]
    @slaves_list = @shards.keys.map {|sym| sym.to_s}.sort 
    @slaves_list.delete('master')   
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

  def select_connection()
    @shards[shard_name].connection()
  end

  def shard_name
    current_shard.is_a?(Array) ? current_shard.first : current_shard
  end
  
  def run_queries_on_shard(shard, &block)
    older_shard = self.current_shard
    self.block = true
    self.current_shard = shard

    begin
      yield
    ensure
      self.block = false
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
  end
  
  def check_schema_migrations(shard)
    if !ActiveRecord::Base.using(shard).connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
      ActiveRecord::Base.using(shard).connection.initialize_schema_migrations_table 
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

  protected
  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end

  def initialize_adapter(adapter)
    begin
      require "active_record/connection_adapters/#{adapter}_adapter"
    rescue LoadError
      raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
    end
  end

  def should_clean_connection?(method)
    method.to_s =~ /insert|select|execute/ && !self.current_group && !@replicated && !self.block
  end

  def should_send_queries_to_replicated_databases?(method)
    @replicated && method.to_s =~ /select/
  end
  
  def have_config_for_enviroment?(config)
    !config[Octopus.env()].nil?
  end

  def send_queries_to_selected_slave(method, *args, &block)        
    old_shard = self.current_shard

    if current_model.read_inheritable_attribute(:replicated) || @entire_replicated
      if !using_enabled
        self.current_shard = @slaves_list.shift.to_sym
        @slaves_list << self.current_shard
      end
    else
      self.current_shard = :master
    end

    sql = select_connection().send(method, *args, &block)     
    self.current_shard = old_shard
    @using_enabled = nil
    return sql    
  end
end
