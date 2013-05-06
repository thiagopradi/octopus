module Octopus
  module Rails2
    module Scope
      def self.included(base)
        base.instance_eval do
          alias_method_chain :proxy_found, :octopus
        end
      end

      def proxy_found_with_octopus
        load_found
      end
    end
  end
end

ActiveRecord::NamedScope::Scope.send(:include, Octopus::Rails2::Scope)
