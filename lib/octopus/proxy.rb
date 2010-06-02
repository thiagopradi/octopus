class Octopus::Proxy
  attr_accessor :shards, :current_shard, :block, :groups, :current_group

  delegate :increment_open_transactions, :decrement_open_transactions,  :to => :select_connection

  def initialize(config)
    @shards = {}
    @groups = {}
    @block = false
    @shards[:master] = ActiveRecord::Base.connection_pool()

    config["production"]["shards"].each do |key, value|
      if value.has_key?("adapter")
        @shards[key.to_sym] = connection_pool_for(value, "mysql_connection")
      else
        @groups[key.to_sym] = []

        value.each do |k, v|
          @shards[k.to_sym] = connection_pool_for(v, "mysql_connection")
          @groups[key.to_sym] << k.to_sym
        end
      end
    end
  end

  def current_shard=(shard_symbol)
    if shard_symbol.is_a?(Array)
      shard_symbol.each {|symbol| raise "Inexistent Shard Name" if @shards[symbol].nil? } 
    else
      raise "Inexistent Shard Name" if @shards[shard_symbol].nil?    
    end

    @current_shard = shard_symbol
  end
  
  def current_group=(group_symbol)
    if group_symbol.is_a?(Array)
      group_symbol.each {|symbol| raise "Inexistent Group Name" if @groups[symbol].nil? } 
    else
      raise "Inexistent Group Name" if @groups[group_symbol].nil? && !group_symbol.nil?
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

  def transaction(start_db_transaction = true, &block)
    if should_send_queries_to_multiple_shards?
      method_return = self.send_transaction_to_shards(current_shard, start_db_transaction, &block)
      self.current_shard = :master
      return method_return
    elsif should_send_queries_to_multiple_groups?
      method_return = nil

      current_group.each do |group_symbol|
        method_return = self.send_transaction_to_shards(@groups[group_symbol], start_db_transaction, &block)
      end

      self.current_group = nil      
      return method_return
    elsif should_send_queries_to_a_group_of_shards?
      method_return = self.send_transaction_to_shards(@groups[current_group], start_db_transaction, &block)
      self.current_group = nil
      return method_return
    else
      select_connection.transaction(start_db_transaction, &block) 
    end
  end

  def method_missing(method, *args, &block)
    if should_clean_connection?(method, &block)
      conn = select_connection()
      self.current_shard = :master
      conn.send(method, *args, &block)
    elsif should_send_queries_to_multiple_groups?
      method_return = nil

      current_group.each do |group_symbol|
        method_return = self.send_queries_to_shards(@groups[group_symbol], method, *args, &block)
      end

      return method_return
    elsif should_send_queries_to_multiple_shards?
      send_queries_to_shards(current_shard, method, *args, &block)
    elsif should_send_queries_to_a_group_of_shards?
      send_queries_to_shards(@groups[current_group], method, *args, &block)
    else
      select_connection().send(method, *args, &block)
    end
  end

  protected
  def should_clean_connection?(method)
    method.to_s =~ /begin_db_transaction|insert|select_value/ && !should_send_queries_to_multiple_shards? && !self.current_group
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


  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end

  def send_transaction_to_shards(shard_array, start_db_transaction, &block)
    shard_array.each do |shard_symbol|
      method_return = @shards[shard_symbol].connection().transaction(start_db_transaction, &block)
    end
  end

  def send_queries_to_shards(shard_array, method, *args, &block)
    method_return = nil

    shard_array.each do |shard_symbol|
      method_return = @shards[shard_symbol].connection().send(method, *args, &block) 
    end

    return method_return
  end
end
