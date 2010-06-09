module Octopus::Model  
  def self.included(base)
    base.extend(ClassMethods)    
    base.send(:include, InstanceMethods)
    
    base.class_eval do 
      def self.connection_proxy
        @@connection_proxy ||= Octopus::Proxy.new(Octopus.config())
      end

      def self.connection 
        if self.respond_to?(:replicated)
          self.connection_proxy().set_replicated_model(self)
        end
        
        self.connection_proxy()
      end

      def self.connected?
        self.connection_proxy().connected?
      end
    end
  end

  module InstanceMethods
    def connection_proxy
      self.class.connection_proxy
    end
    
    def using(shard, &block)
      if block_given?
        older_shard = self.connection_proxy.current_shard
        self.connection_proxy.block = true
        self.connection_proxy.current_shard = shard
        begin
          yield
        ensure
          self.connection_proxy.block = false
          self.connection_proxy.current_shard = older_shard
        end
      else
        self.connection_proxy.current_shard = shard
        return self
      end
    end
  end

  module ClassMethods
    include InstanceMethods

    def replicated_model()
      self.cattr_accessor :replicated
    end
  end  
end

ActiveRecord::Base.send(:include, Octopus::Model)