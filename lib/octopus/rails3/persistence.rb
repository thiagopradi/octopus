module Octopus
  module Rails3
    module Persistence
      def reload_connection()
        set_connection() if should_set_current_shard?
      end

      def update_attribute(name, value)
        reload_connection()
        super(name, value)
      end

      def update_attributes(attributes)
        reload_connection()
        super(attributes)
      end

      def update_attributes!(attributes)
        reload_connection()
        super(attributes)
      end

      def reload
        reload_connection()
        super
      end

      def delete
        reload_connection()
        super
      end

      def destroy
        reload_connection()
        super
      end
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Rails3::Persistence)