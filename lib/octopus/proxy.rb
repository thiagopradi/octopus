class Octopus::Proxy
  attr_accessor :shards

  delegate :add_limit_offset!, :select_value, :quote, :primary_key, :prefetch_primary_key?, :quote_column_name, 
  :quote_table_name, :select_all,
  :decrement_open_transactions, :adapter_name, :initialize_schema_migrations_table, :rollback_db_transaction, 
  :supports_migrations?, :columns, :begin_db_transaction, :increment_open_transactions, 
  :insert, :update, :delete, :create_table, :rename_table, :drop_table, :add_column, :remove_column, 
  :supports_ddl_transactions?,:select_values, :change_column, :change_column_default, :rename_column, :add_index,
  :remove_index, :initialize_schema_information, :dump_schema_information, :execute, :execute_ignore_duplicate, 
  :disable_referential_integrity, :tables, :truncate_table, :to => :select_connection

  def initialize(config)
    @shards = {}
    @shards[:master] = ActiveRecord::Base.connection_pool()

    config["test"]["shards"].each do |key, value|
      @shards[key.to_sym] = connection_pool_for(value, "mysql_connection")
    end
  end

  def select_connection()
    @shards[shard_name].connection()
  end

  def connected?
    true
  end

  def shard_name
    current_shard || :master
  end

  def in_transaction?
    current_shard == :master
  end

  def current_shard
    ActiveRecord::Base.current_shard()
  end

  def transaction(start_db_transaction = true, &block)
    return yield if in_transaction?

    select_connection.transaction(start_db_transaction, &block) 
  end

  def connection_pool_for(adapter, config)
    ActiveRecord::ConnectionAdapters::ConnectionPool.new(ActiveRecord::Base::ConnectionSpecification.new(adapter, config))
  end
 
  private
  def method_missing(method, *args, &block)
    select_connection().send(method, *args, &block)
  end
end
