module Octopus::Model  
  def self.included(base)
    base.extend(ClassMethods)    
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def connection_proxy
      self.class.connection_proxy
    end
    
    def hijack_connection()
      class << self
        def connection_proxy
          @@connection_proxy ||= Octopus::Proxy.new(Octopus.config())
        end

        def connection 
          if self.respond_to?(:replicated)
            self.connection_proxy().set_replicated_model(self)
          end

          self.connection_proxy()
        end

        def connected?
          connection.connected?
        end
      end
    end
    
    def clean_table_name
      self.reset_table_name() if self != ActiveRecord::Base && self.respond_to?(:reset_table_name)
    end
    
    def using(shard, &block)
      hijack_connection()      
      clean_table_name()
      
      if block_given?
        self.connection_proxy.run_query_on_shard(shard, &block)
      else
        self.connection_proxy.current_shard = shard
        self.connection_proxy.using_enabled = true
        
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