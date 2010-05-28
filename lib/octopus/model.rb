module Octopus::Model  
  def self.included(base)
    base.extend ClassMethods
    base.cattr_accessor :connection_proxy
    base.connection_proxy = Octopus::Proxy.new(Octopus.config())
    
    class << base
      def connection
        self.connection_proxy 
      end

      def connected?
        self.connection_proxy.connected?
      end
    end
  end

  module ClassMethods
    def using(args)
      connection.current_shard = args
      return self
    end
  end
end

ActiveRecord::Base.send(:include, Octopus::Model)