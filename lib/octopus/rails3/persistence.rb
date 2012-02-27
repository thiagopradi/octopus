module Octopus
  module Rails3
    module Persistence
      def update_attribute(name, value)
        reload_connection()
        super
      end

      def update_attributes(attributes, options = {})
        reload_connection()
        super
      end

      def update_attributes!(attributes, options = {})
        reload_connection()
        super
      end

      def reload(options = nil)
        reload_connection()
        super(options)
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
