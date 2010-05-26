class Octopus::Proxy
  attr_accessor :options
  
  delegate :insert, :update, :delete, :create_table, :rename_table, :drop_table, :add_column, :remove_column, 
    :change_column, :change_column_default, :rename_column, :add_index, :remove_index, :initialize_schema_information,
    :dump_schema_information, :execute, :execute_ignore_duplicate, :column_names, :to => :select_shard
  
  def initialize(master_class, options)
    @options = options
  end
  
  def select_shard()
    connection
  end
end
