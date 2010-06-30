class ActiveRecord::Associations::HasAndBelongsToManyAssociation
  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end

  def insert_record(record, force = true, validate = true)
    if has_primary_key?
      raise ActiveRecord::ConfigurationError,
      "Primary key is not allowed in a has_and_belongs_to_many join table (#{@reflection.options[:join_table]})."
    end

    if record.new_record?
      if force
        record.save!
      else
        return false unless record.save(validate)
      end
    end

    if @reflection.options[:insert_sql]
      if should_wrap_the_connection?
        @owner.using(@owner.current_shard) {  @owner.connection.insert(interpolate_sql(@reflection.options[:insert_sql], record)) } 
      else
        @owner.connection.insert(interpolate_sql(@reflection.options[:insert_sql], record))
      end
    else
      attributes = columns.inject({}) do |attrs, column|
        case column.name.to_s
        when @reflection.primary_key_name.to_s
          attrs[column.name] = owner_quoted_id
        when @reflection.association_foreign_key.to_s
          attrs[column.name] = record.quoted_id
        else
          if record.has_attribute?(column.name)
            value = @owner.send(:quote_value, record[column.name], column)
            attrs[column.name] = value unless value.nil?
          end
        end
        attrs
      end

      sql =
      "INSERT INTO #{@owner.connection.quote_table_name @reflection.options[:join_table]} (#{@owner.send(:quoted_column_names, attributes).join(', ')}) " +
      "VALUES (#{attributes.values.join(', ')})"

      if should_wrap_the_connection?
        @owner.using(@owner.current_shard) {  @owner.connection.insert(sql) } 
      else
        @owner.connection.insert(sql)
      end
    end

    return true
  end
end