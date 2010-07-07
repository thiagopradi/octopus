module Octopus
  module Rails2
    module Persistence
      def self.included(base)
        base.instance_eval do 
          alias_method_chain :destroy, :octopus
          alias_method_chain :delete, :octopus
          alias_method_chain :reload, :octopus
        end
      end

      def delete_with_octopus()
        if should_set_current_shard?
          self.using(self.current_shard) do
            delete_without_octopus()
          end
        else
          delete_without_octopus()
        end
      end

      def destroy_with_octopus()
        if should_set_current_shard?
          self.using(self.current_shard) do
            destroy_without_octopus()
          end
        else
          destroy_without_octopus()
        end
      end

      def reload_with_octopus(options = nil)
        if should_set_current_shard?
          self.using(self.current_shard) do
            reload_without_octopus(options)
          end
        else
          reload_without_octopus(options)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Rails2::Persistence)