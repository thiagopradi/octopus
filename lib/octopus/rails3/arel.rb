class Arel::Visitors::ToSql
  def quote value, column = nil
    @connection.quote value, column
  end

  def quote_table_name name
    @connection.quote_table_name(name)
  end

  def quote_column_name name
    Arel::Nodes::SqlLiteral === name ? name : @connection.quote_column_name(name)
  end
end
