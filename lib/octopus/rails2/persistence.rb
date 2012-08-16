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
          Octopus.using(self.current_shard) { delete_without_octopus() }
        else
          delete_without_octopus()
        end
      end

      def destroy_with_octopus()
        if should_set_current_shard?
          Octopus.using(self.current_shard) { destroy_without_octopus() }
        else
          destroy_without_octopus()
        end
      end

      def reload_with_octopus(options = nil)
        if should_set_current_shard?
          Octopus.using(self.current_shard) { reload_without_octopus(options) }
        else
          reload_without_octopus(options)
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Rails2::Persistence)