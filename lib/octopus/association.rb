module Octopus::Association
  def collection_reader_method(reflection, association_proxy_class)
    define_method(reflection.name) do |*params|
      if self.respond_to?(:current_shard)
        self.class.connection_proxy.run_query_on_shard self.current_shard do 
          force_reload = params.first unless params.empty?
          association = association_instance_get(reflection.name)

          unless association
            association = association_proxy_class.new(self, reflection)
            association_instance_set(reflection.name, association)
          end

          reflection.klass.uncached { association.reload } if force_reload

          association
        end
      else
        force_reload = params.first unless params.empty?
        association = association_instance_get(reflection.name)

        unless association
          association = association_proxy_class.new(self, reflection)
          association_instance_set(reflection.name, association)
        end

        reflection.klass.uncached { association.reload } if force_reload

        association
      end
    end

    define_method("#{reflection.name.to_s.singularize}_ids") do
      if self.respond_to?(:current_shard)
        self.class.connection_proxy.run_query_on_shard self.current_shard do 
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
      else
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
end

ActiveRecord::Base.extend(Octopus::Association)