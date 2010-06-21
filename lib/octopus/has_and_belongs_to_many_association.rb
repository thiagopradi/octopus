class ActiveRecord::Associations::HasAndBelongsToManyAssociation
  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end
  
  def insert_record(record, force = true, validate = true)
    if record.new_record?
      if force
        record.save!
      else
        return false unless record.save(:validate => validate)
      end
    end

    if @reflection.options[:insert_sql]
      @owner.connection.insert(interpolate_sql(@reflection.options[:insert_sql], record))
    else
      relation = Arel::Table.new(@reflection.options[:join_table])
      attributes = columns.inject({}) do |attrs, column|
        case column.name.to_s
        when @reflection.primary_key_name.to_s
          attrs[relation[column.name]] = owner_quoted_id
        when @reflection.association_foreign_key.to_s
          attrs[relation[column.name]] = record.quoted_id
        else
          if record.has_attribute?(column.name)
            value = @owner.send(:quote_value, record[column.name], column)
            attrs[relation[column.name]] = value unless value.nil?
          end
        end
        attrs
      end
      
      if should_wrap_the_connection?
        @owner.using(@owner.current_shard) { relation.insert(attributes) } 
      else
        relation.insert(attributes)
      end
    end

    return true
  end
end