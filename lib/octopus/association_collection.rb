class ActiveRecord::Associations::AssociationCollection
  def should_wrap_the_connection?
    @owner.current_shard != nil
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


  def clear
    return self if length.zero? # forces load_target if it hasn't happened already

    if @reflection.options[:dependent] && @reflection.options[:dependent] == :destroy
      if should_wrap_the_connection?
        @owner.using(@owner.current_shard) { destroy_all } 
      else        
        destroy_all
      end
    else          
      if should_wrap_the_connection?
        @owner.using(@owner.current_shard) { delete_all } 
      else        
        delete_all
      end
    end

    self
  end

  def create_record(attrs)
    attrs.update(@reflection.options[:conditions]) if @reflection.options[:conditions].is_a?(Hash)
    ensure_owner_is_not_new
    record = @reflection.klass.send(:with_scope, :create => construct_scope[:create]) do
      @reflection.build_association(attrs)
    end
    record.current_shard = @owner.current_shard if should_wrap_the_connection?
    if block_given?
      add_record_to_target_with_callbacks(record) { |*block_args| yield(*block_args) }
    else
      add_record_to_target_with_callbacks(record)
    end
  end

  def build(attributes = {}, &block)
    if attributes.is_a?(Array)
      attributes.collect { |attr| build(attr, &block) }
    else
      build_record(attributes) do |record|
        record.current_shard = @owner.current_shard if should_wrap_the_connection?
        block.call(record) if block_given?
        set_belongs_to_association_for(record)
      end
    end
  end
end