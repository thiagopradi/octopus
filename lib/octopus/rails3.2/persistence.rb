module Octopus
  module Rails32
    module Persistence
      def update_column(*args)
        reload_connection()
        super
      end
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Rails32::Persistence)
