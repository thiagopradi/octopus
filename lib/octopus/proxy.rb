class Octopus::Proxy
  attr_accessor :shards, :current_shard, :block, :groups, :current_group,  :replicated, :slaves_list, :replicated_models

  delegate :increment_open_transactions, :decrement_open_transactions,  :to => :select_connection

  def initialize(config)
    @shards = {}
    @groups = {}
    @replicated_models = []
    @block = false
    @replicated = config[Octopus.env()]["replicated"] || false
    @shards[:master] = ActiveRecord::Base.connection_pool()

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

    if @replicated
      @slaves_list = @shards.keys
      @slaves_list.delete(:master)
      @slaves_list = @slaves_list.map {|sym| sym.to_s}.sort
    end
  end

  def current_shard=(shard_symbol)
    if shard_symbol.is_a?(Array)
      shard_symbol.each {|symbol| raise "Nonexistent Shard Name" if @shards[symbol].nil? }
    else
      raise "Nonexistent Shard Name" if @shards[shard_symbol].nil?
    end

    @current_shard = shard_symbol
  end

  def current_group=(group_symbol)
    if group_symbol.is_a?(Array)
      group_symbol.each {|symbol| raise "Nonexistent Group Name" if @groups[symbol].nil? }
    else
      raise "Nonexistent Group Name" if @groups[group_symbol].nil? && !group_symbol.nil?
    end

    @current_group = group_symbol
  end

  def select_connection()
    @shards[shard_name].connection()
  end

  def shard_name
    if(current_shard.is_a?(Array))
      current_shard.first
    else
      current_shard || :master
    end
  end
  
  def set_replicated_model(model)
    replicated_models << model if !replicated_models.include?(model)
  end

  def transaction(start_db_transaction = true, &block)
    if should_send_queries_to_multiple_shards?
      self.send_transaction_to_multiple_shards(current_shard, start_db_transaction, &block)
      self.current_shard = :master
    elsif should_send_queries_to_multiple_groups?
      self.send_transaction_to_multiple_groups(start_db_transaction, &block)
      self.current_group = nil      
    elsif should_send_queries_to_a_group_of_shards?
      self.send_transaction_to_multiple_shards(@groups[current_group], start_db_transaction, &block)
      self.current_group = nil
    else
      select_connection.transaction(start_db_transaction, &block) 
    end
  end

  def method_missing(method, *args, &block)
    if should_clean_connection?(method, &block)
      conn = select_connection()
      self.current_shard = :master
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

  protected
  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end

  def initialize_adapter(adapter)
    begin
      require 'rubygems'
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
    method.to_s =~ /begin_db_transaction|insert|select/ && !should_send_queries_to_multiple_shards? && !self.current_group && !replicated
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
    @replicated && method.to_s == "select_all"
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
    #TODO: ugly code, needs refactor
    if args.last =~ /#{replicated_models.join('|')}/
      old_shard = self.current_shard
      self.current_shard = slaves_list.shift.to_sym
      slaves_list << self.current_shard      
    else
      old_shard = self.current_shard
      self.current_shard = :master
    end

    sql = select_connection().send(method, *args, &block)     
    self.current_shard = old_shard 
    return sql    
  end

  def send_transaction_to_multiple_shards(shard_array, start_db_transaction, &block)
    shard_array.each do |shard_symbol|
      @shards[shard_symbol].connection().transaction(start_db_transaction, &block)
    end
  end

  def send_transaction_to_multiple_groups(start_db_transaction, &block)
    current_group.each do |group_symbol|
      self.send_transaction_to_multiple_shards(@groups[group_symbol], start_db_transaction, &block)
    end
  end
end
