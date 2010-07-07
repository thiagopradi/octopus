module Octopus
  module Rails2
    module Association
      def association_accessor_methods(reflection, association_proxy_class)
        define_method(reflection.name) do |*params|
          force_reload = params.first unless params.empty?
          reload_connection()
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
          reload_connection()
          association = association_instance_get(reflection.name)
          association && association.loaded?
        end

        define_method("#{reflection.name}=") do |new_value|
          association = association_instance_get(reflection.name)
          reload_connection()
          if association.nil? || association.target != new_value
            association = association_proxy_class.new(self, reflection)
          end

          if association_proxy_class == ActiveRecord::Associations::HasOneThroughAssociation
            association.create_through_record(new_value)
            if new_record?
              association_instance_set(reflection.name, new_value.nil? ? nil : association)
            else
              self.send(reflection.name, new_value)
            end
          else
            association.replace(new_value)
            association_instance_set(reflection.name, new_value.nil? ? nil : association)
          end
        end

        define_method("set_#{reflection.name}_target") do |target|
          reload_connection()
          return if target.nil? and association_proxy_class == ActiveRecord::Associations::BelongsToAssociation
          association = association_proxy_class.new(self, reflection)
          association.target = target
          association_instance_set(reflection.name, association)
        end
      end

      def collection_reader_method(reflection, association_proxy_class)
        define_method(reflection.name) do |*params|
          force_reload = params.first unless params.empty?
          reload_connection() 
          association = association_instance_get(reflection.name)

          unless association
            association = association_proxy_class.new(self, reflection)
            association_instance_set(reflection.name, association)
          end

          reflection.klass.uncached { association.reload } if force_reload

          association
        end

        define_method("#{reflection.name.to_s.singularize}_ids") do
          reload_connection() 
          if send(reflection.name).loaded? || reflection.options[:finder_sql]
            send(reflection.name).map(&:id)
          else
            send(reflection.name).all(:select => "#{reflection.quoted_table_name}.#{reflection.klass.primary_key}").map(&:id)
          end
        end
      end

      def collection_accessor_methods(reflection, association_proxy_class, writer = true)
        collection_reader_method(reflection, association_proxy_class)

        if writer
          define_method("#{reflection.name}=") do |new_value|
            reload_connection()
            # Loads proxy class instance (defined in collection_reader_method) if not already loaded
            association = send(reflection.name)
            association.replace(new_value)
            association
          end

          define_method("#{reflection.name.to_s.singularize}_ids=") do |new_value|
            reload_connection()
            ids = (new_value || []).reject { |nid| nid.blank? }.map(&:to_i)
            send("#{reflection.name}=", reflection.klass.find(ids).index_by(&:id).values_at(*ids))
          end
        end
      end

      def association_constructor_method(constructor, reflection, association_proxy_class)
        define_method("#{constructor}_#{reflection.name}") do |*params|
          reload_connection() 
          attributees      = params.first unless params.empty?
          replace_existing = params[1].nil? ? true : params[1]
          association      = association_instance_get(reflection.name)

          unless association
            association = association_proxy_class.new(self, reflection)
            association_instance_set(reflection.name, association)
          end

          if association_proxy_class == ActiveRecord::Associations::HasOneAssociation
            ret_val = association.send(constructor, attributees, replace_existing)
          else
            ret_val = association.send(constructor, attributees)
          end

          if should_set_current_shard?
            ret_val.current_shard = self.current_shard
          end

          return ret_val
        end
      end
    end
  end
end

ActiveRecord::Base.extend(Octopus::Rails2::Association)
