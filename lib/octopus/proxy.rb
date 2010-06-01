class Octopus::Proxy
  attr_accessor :shards, :current_shard, :block, :multiple_shards

  delegate :increment_open_transactions, :decrement_open_transactions,  :to => :select_connection

  def initialize(config)
    @shards = {}
    @block = false
    @multiple_shards = false
    @shards[:master] = ActiveRecord::Base.connection_pool()

    config["test"]["shards"].each do |key, value|
      @shards[key.to_sym] = connection_pool_for(value, "mysql_connection")
    end
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
    if(multiple_shards && current_shard.is_a?(Array))
      method_return = nil
      
      current_shard.each do |shard_symbol|
        method_return = @shards[shard_symbol].connection().transaction(start_db_transaction, &block) 
      end
      
      self.multiple_shards = false
      self.current_shard = :master
      return method_return
    else
      select_connection.transaction(start_db_transaction, &block) 
    end
  end

  def method_missing(method, *args, &block)
    if(method.to_s =~ /begin_db_transaction|insert|select_value/ && !block && !multiple_shards)
      conn = select_connection()
      self.current_shard = :master
      conn.send(method, *args, &block)
    elsif(multiple_shards && current_shard.is_a?(Array))
      method_return = nil
      
      current_shard.each do |shard_symbol|
        method_return = @shards[shard_symbol].connection().send(method, *args, &block) 
      end
      
      return method_return
    else
      select_connection().send(method, *args, &block)
    end
  end

  protected
  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end
end
