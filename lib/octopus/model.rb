module Octopus::Model  
  def self.included(base)
    base.extend ClassMethods
    
    class << base
      def connection
        self.connection_proxy 
      end

      def connected?
        self.connection_proxy.connected?
      end

      def connection_pool
        raise "dynamic connection switching means you cannot get direct access to a pool"
      end
    end
  end

  module ClassMethods
    def using(args)
      ActiveRecord::Base.current_shard = args
      return self
    end
    
    def connection()
      ActiveRecord::Base.connection_proxy()
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Model)