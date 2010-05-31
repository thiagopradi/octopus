module Octopus::Model  
  def self.included(base)
    base.extend(ClassMethods)
    base.cattr_accessor :connection_proxy
    base.connection_proxy = Octopus::Proxy.new(Octopus.config())
    base.send(:include, InstanceMethods)
    
    class << base
      def connection
        self.connection_proxy()
      end

      def connected?
        self.connection_proxy().connected?
      end
    end
  end
  
  module InstanceMethods
    def using_shard(shard, &block)
      older_shard = self.connection_proxy.current_shard
      self.connection_proxy.block = true
      self.connection_proxy.current_shard = shard
      yield
      self.connection_proxy.block = false
      self.connection_proxy.current_shard = older_shard      
    end
  end
  
  module ClassMethods
    def using(args)
      self.connection_proxy.current_shard = args
      return self
    end
    
    def using_shard(shard, &block)
      older_shard = self.connection_proxy.current_shard
      self.connection_proxy.block = true
      self.connection_proxy.current_shard = shard
      yield
      self.connection_proxy.block = false
      self.connection_proxy.current_shard = older_shard      
    end
  end  
end

ActiveRecord::Base.send(:include, Octopus::Model)