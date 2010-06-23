class Octopus::Proxy
  attr_accessor :current_model, :current_shard, :current_group, :block, :using_enabled, :last_current_shard

  def initialize(config)
    initialize_shards(config)
    
    if config[Octopus.env()]["replicated"]
      initialize_replication()
    end
  end
  
  def initialize_shards(config)
    @shards = {}
    @groups = {}
    @shards[:master] = ActiveRecord::Base.connection_pool()
    @current_shard = :master
    
    config[Octopus.env()]["shards"].each do |key, value|
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
  
  def initialize_replication()
    @replicated = true
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
    
  def add_transaction_record(record)
    if !select_connection().instance_variable_get(:@_current_transaction_records).nil?
      select_connection().add_transaction_record(record)
    end
  end

  def transaction(options = {}, &block)
    if should_send_queries_to_multiple_shards?
      self.send_transaction_to_multiple_shards(current_shard, options, &block)
    elsif should_send_queries_to_multiple_groups?
      self.send_transaction_to_multiple_groups(options, &block)
    elsif should_send_queries_to_a_group_of_shards?
      self.send_transaction_to_multiple_shards(@groups[current_group], options, &block)
      @current_group = nil      
    else
      select_connection.transaction(options, &block) 
    end
  end

  def method_missing(method, *args, &block)
    if should_clean_connection?(method)
      conn = select_connection()
      self.last_current_shard = self.current_shard
      self.current_shard = :master
      @using_enabled = nil
      conn.send(method, *args, &block)
    elsif should_send_queries_to_replicated_databases?(method)
      send_queries_to_selected_slave(method, *args, &block)      
    elsif should_send_queries_to_multiple_groups?
      send_queries_to_multiple_groups(method, *args, &block)
    elsif should_send_queries_to_multiple_shards?
      send_queries_to_shards(current_shard, method, *args, &block)
    elsif should_send_queries_to_a_group_of_shards?
      send_queries_to_shards(@groups[current_group], method, *args, &block)
    else
      select_connection().send(method, *args, &block)
    end
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
  
  protected
  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end

  def initialize_adapter(adapter)
    begin
      gem "activerecord-#{adapter}-adapter"
      require "active_record/connection_adapters/#{adapter}_adapter"
    rescue LoadError
      begin
        require "active_record/connection_adapters/#{adapter}_adapter"
      rescue LoadError
        raise "Please install the #{adapter} adapter: `gem install activerecord-#{adapter}-adapter` (#{$!})"
      end
    end
  end

  def should_clean_connection?(method)
    method.to_s =~ /insert|select/ && !should_send_queries_to_multiple_shards? && !self.current_group && !@replicated
  end

  def should_send_queries_to_multiple_shards?
    current_shard.is_a?(Array)
  end

  def should_send_queries_to_multiple_groups?
    current_group.is_a?(Array)
  end

  def should_send_queries_to_a_group_of_shards?
    !current_group.nil?
  end

  def should_send_queries_to_replicated_databases?(method)
    @replicated && method.to_s =~ /select/
  end

  def send_queries_to_multiple_groups(method, *args, &block)
    method_return = nil

    current_group.each do |group_symbol|
      method_return = self.send_queries_to_shards(@groups[group_symbol], method, *args, &block)
    end

    return method_return
  end

  def send_queries_to_shards(shard_array, method, *args, &block)
    method_return = nil

    shard_array.each do |shard_symbol|
      method_return = @shards[shard_symbol].connection().send(method, *args, &block) 
    end

    return method_return
  end

  def send_queries_to_selected_slave(method, *args, &block)        
    old_shard = self.current_shard
    
    if current_model.read_inheritable_attribute(:replicated)
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

  def send_transaction_to_multiple_shards(shard_array, options, &block)
    shard_array.each do |shard_symbol|
      @shards[shard_symbol].connection().transaction(options, &block)
    end
  end

  def send_transaction_to_multiple_groups(options, &block)
    current_group.each do |group_symbol|
      self.send_transaction_to_multiple_shards(@groups[group_symbol], options, &block)
    end
  end
end
