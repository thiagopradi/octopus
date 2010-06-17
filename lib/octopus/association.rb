module Octopus::Association
  def self.extended(base)
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def save(*)
      set_connection() if self.respond_to?(:current_shard)
      super
    end

    def save!(*)
      set_connection() if self.respond_to?(:current_shard)
      super
    end

    def delete
      set_connection() if self.respond_to?(:current_shard)
      super
    end

    def destroy
      set_connection() if self.respond_to?(:current_shard)
      super
    end

    def update_attribute(name, value)
      set_connection() if self.respond_to?(:current_shard)
      super(name, value)
    end

    def update_attributes(attributes)
      set_connection() if self.respond_to?(:current_shard)
      super(attributes)
    end

    def update_attributes!(attributes)
      set_connection() if self.respond_to?(:current_shard)
      super(attributes)
    end

    def increment(attribute, by=1)
      set_connection() if self.respond_to?(:current_shard)
      super(attribute, by)
    end

    def increment!(attribute, by=1)
      set_connection() if self.respond_to?(:current_shard)
      super(attribute, by)
    end

    def decrement(attribute, by=1)
      set_connection() if self.respond_to?(:current_shard)
      super(attribute, by)
    end

    def decrement!(attribute, by=1)
      set_connection() if self.respond_to?(:current_shard)
      super(attribute, by)
    end

    def toggle(attribute)
      set_connection() if self.respond_to?(:current_shard)
      super(attribute)
    end

    def toggle!(attribute)
      set_connection() if self.respond_to?(:current_shard) 
      super(attribute)
    end
  end

  def collection_reader_method(reflection, association_proxy_class)
    define_method(reflection.name) do |*params|
      force_reload = params.first unless params.empty?
      if self.respond_to?(:current_shard) 
        force_reload = true
        set_connection()
      end

      association = association_instance_get(reflection.name)

      unless association
        association  = association_proxy_class.new(self, reflection)
        association_instance_set(reflection.name, association)
      end

      reflection.klass.uncached { association.reload } if force_reload

      association
    end

    def association_constructor_method(constructor, reflection, association_proxy_class)
      define_method("#{constructor}_#{reflection.name}") do |*params|
        if self.respond_to?(:current_shard) 
          set_connection()
        end
        attributees      = params.first unless params.empty?
        replace_existing = params[1].nil? ? true : params[1]
        association      = association_instance_get(reflection.name)

        unless association
          association = association_proxy_class.new(self, reflection)
          association_instance_set(reflection.name, association)
        end

        if association_proxy_class == ActiveRecord::Associations::HasOneAssociation
          association.send(constructor, attributees, replace_existing)
        else
          association.send(constructor, attributees)
        end
      end
    end

    def association_accessor_methods(reflection, association_proxy_class)
      define_method(reflection.name) do |*params|
        force_reload = params.first unless params.empty?
        if self.respond_to?(:current_shard)
          force_reload = true
          set_connection()
        end
        association = association_instance_get(reflection.name)

        if association.nil? || force_reload
          association = association_proxy_class.new(self, reflection)
          retval = force_reload ? reflection.klass.uncached { association.reload } : association.reload
          if retval.nil? and association_proxy_class == ActiveRecord::Associations::BelongsToAssociation
            association_instance_set(reflection.name, nil)
            return nil
          end
          association_instance_set(reflection.name, association)
        end

        association.target.nil? ? nil : association
      end

      define_method("loaded_#{reflection.name}?") do
        if self.respond_to?(:current_shard)
          set_connection()
        end
        association = association_instance_get(reflection.name)
        association && association.loaded?
      end

      define_method("#{reflection.name}=") do |new_value|
        if self.respond_to?(:current_shard) 
          set_connection()
        end
        association = association_instance_get(reflection.name)

        if association.nil? || association.target != new_value
          association = association_proxy_class.new(self, reflection)
        end

        association.replace(new_value)
        association_instance_set(reflection.name, new_value.nil? ? nil : association)
      end

      define_method("set_#{reflection.name}_target") do |target|
        return if target.nil? and association_proxy_class == ActiveRecord::Associations::BelongsToAssociation
        if self.respond_to?(:current_shard) && self.current_shard != nil
          set_connection()
        end
        association = association_proxy_class.new(self, reflection)
        association.target = target
        association_instance_set(reflection.name, association)
      end
    end


    define_method("#{reflection.name.to_s.singularize}_ids") do
      set_connection() if self.respond_to?(:current_shard)        
      if send(reflection.name).loaded? || reflection.options[:finder_sql]
        send(reflection.name).map(&:id)
      else
        if reflection.through_reflection && reflection.source_reflection.belongs_to?
          through = reflection.through_reflection
          primary_key = reflection.source_reflection.primary_key_name
          send(through.name).select("DISTINCT #{through.quoted_table_name}.#{primary_key}").map!(&:"#{primary_key}")
        else
          send(reflection.name).select("#{reflection.quoted_table_name}.#{reflection.klass.primary_key}").except(:includes).map!(&:id)
        end
      end
    end
  end
end


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


ActiveRecord::Base.extend(Octopus::Association)
