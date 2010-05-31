class Octopus::Proxy
  attr_accessor :shards, :current_shard, :block

  delegate :increment_open_transactions, :decrement_open_transactions, :to => :select_connection

  def initialize(config)
    @shards = {}
    @block = false
    @shards[:master] = ActiveRecord::Base.connection_pool()
    
    config["test"]["shards"].each do |key, value|
      @shards[key.to_sym] = connection_pool_for(value, "mysql_connection")
    end
  end

  def select_connection()
    @shards[shard_name].connection()
  end

  def shard_name
    current_shard || :master
  end

  def in_transaction?
    current_shard == :master
  end

  def transaction(start_db_transaction = true, &block)
    return yield if in_transaction?

    select_connection.transaction(start_db_transaction, &block) 
  end

  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end

  def method_missing(method, *args, &block)
    if(method.to_s =~ /begin_db_transaction|insert|select_value/ && !block)
       conn = select_connection()
       self.current_shard = :master
       conn.send(method, *args, &block)
    else
      select_connection().send(method, *args, &block)
    end
  end
end
