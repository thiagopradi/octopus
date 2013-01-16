module Octopus
  module Rails2
    module Association
      def association_accessor_methods(reflection, association_proxy_class)
        super

        define_method("#{reflection.name}_with_octopus") do |*params|
          reload_connection
          send("#{reflection.name}_without_octopus", *params)
        end

        define_method("loaded_#{reflection.name}_with_octopus?") do
          reload_connection
          send("loaded_#{reflection.name}_without_octopus?")
        end

        define_method("#{reflection.name}_with_octopus=") do |new_value|
          reload_connection
          send("#{reflection.name}_without_octopus=", new_value)
        end

        define_method("set_#{reflection.name}_target_with_octopus") do |target|
          reload_connection
          send("set_#{reflection.name}_target_without_octopus", target)
        end

        alias_method_chain reflection.name, "octopus"
        alias_method_chain "loaded_#{reflection.name}?", "octopus"
        alias_method_chain "#{reflection.name}=", "octopus"
        alias_method_chain "set_#{reflection.name}_target", "octopus"
      end

      def collection_reader_method(reflection, association_proxy_class)
        super

        define_method("#{reflection.name}_with_octopus") do |*params|
          reload_connection
          send("#{reflection.name}_without_octopus", *params)
        end

        define_method("#{reflection.name.to_s.singularize}_ids_with_octopus") do
          reload_connection
          send("#{reflection.name.to_s.singularize}_ids_without_octopus")
        end

        alias_method_chain reflection.name, "octopus"
        alias_method_chain "#{reflection.name.to_s.singularize}_ids", "octopus"
      end

      def collection_accessor_methods(reflection, association_proxy_class, writer = true)
        super

        if writer
          define_method("#{reflection.name}_with_octopus=") do |new_value|
            reload_connection
            send("#{reflection.name}_without_octopus=", new_value)
          end

          define_method("#{reflection.name.to_s.singularize}_ids_with_octopus=") do |new_value|
            reload_connection
            send("#{reflection.name.to_s.singularize}_ids_without_octopus=", new_value)
          end

          alias_method_chain "#{reflection.name}=", "octopus"
          alias_method_chain "#{reflection.name.to_s.singularize}_ids=", "octopus"
        end
      end

      def association_constructor_method(constructor, reflection, association_proxy_class)
        super

        define_method("#{constructor}_#{reflection.name}_with_octopus") do |*params|
          reload_connection
          result = send("#{constructor}_#{reflection.name}_without_octopus", *params)

          result.current_shard = current_shard if should_set_current_shard?
          result
        end

        alias_method_chain "#{constructor}_#{reflection.name}", "octopus"
      end
    end
  end
end

ActiveRecord::Base.extend(Octopus::Rails2::Association)
