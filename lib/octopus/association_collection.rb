class ActiveRecord::Associations::AssociationCollection
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
        if @owner.current_shard != nil
          @owner.using @owner.current_shard do 
            @reflection.klass.count(column_name, options) 
          end
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

  def find(*args)
    options = args.extract_options!
    if @owner.current_shard != nil
      @owner.using @owner.current_shard do 

        # If using a custom finder_sql, scan the entire collection.
        if @reflection.options[:finder_sql]
          expects_array = args.first.kind_of?(Array)
          ids           = args.flatten.compact.uniq.map { |arg| arg.to_i }

          if ids.size == 1
            id = ids.first
            record = load_target.detect { |r| id == r.id }
            expects_array ? [ record ] : record
          else
            load_target.select { |r| ids.include?(r.id) }
          end
        else
          merge_options_from_reflection!(options)
          construct_find_options!(options)

          find_scope = construct_scope[:find].slice(:conditions, :order)

          with_scope(:find => find_scope) do
            relation = @reflection.klass.send(:construct_finder_arel, options, @reflection.klass.send(:current_scoped_methods))

            case args.first
            when :first, :last

              relation.send(args.first)
            when :all
              records = relation.all
              @reflection.options[:uniq] ? uniq(records) : records
            else
              relation.find(*args)            
            end
          end
        end
      end
    end
  end


  def delete(*records)
    remove_records(records) do |records, old_records|
      if @owner.current_shard != nil
        @owner.using @owner.current_shard do 
          delete_records(old_records) if old_records.any?
        end
      else
        delete_records(old_records) if old_records.any?      
      end

      records.each do |record| 
        @target.delete(record) 
      end
    end
  end

  def clear
    return self if length.zero? # forces load_target if it hasn't happened already

    if @reflection.options[:dependent] && @reflection.options[:dependent] == :destroy
      if @owner.current_shard != nil
        @owner.using @owner.current_shard do 
          destroy_all
        end
      else        
        destroy_all
      end
    else          
      if @owner.current_shard != nil
        @owner.using @owner.current_shard do 
          delete_all
        end
      else        
        delete_all
      end
    end

    self
  end

  def create(attrs = {})
    if attrs.is_a?(Array)
      attrs.collect { |attr| create(attr) }
    else
      create_record(attrs) do |record|
        yield(record) if block_given?
        record.current_shard = @owner.current_shard
        record.save
      end
    end
  end

  def create!(attrs = {})
    create_record(attrs) do |record|
      yield(record) if block_given?
      record.current_shard = @owner.current_shard      
      record.save!
    end
  end

  def build(attributes = {}, &block)
    if attributes.is_a?(Array)
      attributes.collect { |attr| build(attr, &block) }
    else
      build_record(attributes) do |record|
        record.current_shard = @owner.current_shard
        block.call(record) if block_given?
        set_belongs_to_association_for(record)
      end
    end
  end
end