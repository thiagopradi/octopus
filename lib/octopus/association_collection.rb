class ActiveRecord::Associations::AssociationCollection
  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end

  def count(column_name = nil, options = {})
    if @reflection.options[:counter_sql]
      @reflection.klass.count_by_sql(@counter_sql)
    else
      column_name, options = nil, column_name if column_name.is_a?(Hash)

      if @reflection.options[:uniq]
        # This is needed because 'SELECT count(DISTINCT *)..' is not valid SQL.
        column_name = "#{@reflection.quoted_table_name}.#{@reflection.klass.primary_key}" unless column_name
        options.merge!(:distinct => true)
      end

      value = @reflection.klass.send(:with_scope, construct_scope) do 
        if should_wrap_the_connection?
          @owner.using(@owner.current_shard) { @reflection.klass.count(column_name, options) } 
        else        
          @reflection.klass.count(column_name, options) 
        end
      end

      limit  = @reflection.options[:limit]
      offset = @reflection.options[:offset]

      if limit || offset
        [ [value - offset.to_i, 0].max, limit.to_i ].min
      else
        value
      end
    end
  end
end