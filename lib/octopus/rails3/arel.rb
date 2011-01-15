class Arel::Visitors::ToSql
  def quote value, column = nil
    ActiveRecord::Base.connection.quote value, column
  end
  
  def quote_table_name name
    ActiveRecord::Base.connection.quote_table_name(name)
  end

  def quote_column_name name
    Arel::Nodes::SqlLiteral === name ? name : ActiveRecord::Base.connection.quote_column_name(name)
  end
end