module Octopus::Model  
  def self.included(base)
    base.extend(ClassMethods)    
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    def hijack_initializer()
      attr_accessor :current_shard
      after_initialize :set_current_shard
      before_save :set_connection
      before_update :set_connection
      before_destroy :set_connection
      
      def set_connection()
        if(!self.current_shard.nil?)
          self.class.connection_proxy.current_shard = self.current_shard
        end
      end
      
      def set_current_shard
        def reload
          set_connection()
          super
        end
         
        if self.class.respond_to?(:connection_proxy) && self.respond_to?(:current_shard)
          if self.new_record?
            self.current_shard = self.class.connection_proxy.current_shard    
          else
            self.current_shard = self.class.connection_proxy.last_current_shard  
          end
        end
      end    
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
        hijack_initializer()  
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