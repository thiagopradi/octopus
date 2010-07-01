module Octopus::Model  
  def self.extended(base) 
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.hijack_connection() unless defined?(::Rails) && (Rails.env == 'test' || Rails.env == 'development')
  end

  module SharedMethods
    def clean_table_name
      self.reset_table_name() if self != ActiveRecord::Base && self.respond_to?(:reset_table_name)
    end

    def using(shard, &block)
      return if defined?(::Rails) && (Rails.env == 'test' || Rails.env == 'development')
      hijack_connection()  
      clean_table_name()

      if block_given?
        self.connection.run_queries_on_shard(shard, &block)
      else
        hijack_initializer()  
        self.connection.using_enabled = true

        return Octopus::ScopeProxy.new(shard, self)
      end
    end

    def hijack_initializer()
      attr_accessor :current_shard
      after_initialize :set_current_shard
      before_save :set_connection

      def set_current_shard
        if new_record?
          self.current_shard = self.class.connection_proxy.current_shard    
        else
          self.current_shard = self.class.connection_proxy.last_current_shard  
        end
      end    
    end

    def hijack_connection()
      class << self
        def connection_proxy
          Thread.current[:connection_proxy] ||= Octopus::Proxy.new(Octopus.config())
        end

        def connection 
          self.connection_proxy().current_model = self
          self.connection_proxy()
        end
      end
    end
  end

  module InstanceMethods
    include SharedMethods

    def set_connection(*args)
      if(args.size == 1)
        arg = args.first
        arg.current_shard = self.current_shard if arg.respond_to?(:current_shard) && have_a_valid_shard?
      end

      self.connection.current_shard = self.current_shard if have_a_valid_shard?
    end

    def have_a_valid_shard?
      self.respond_to?(:current_shard) && self.current_shard != nil
    end
  end

  module ClassMethods
    include SharedMethods

    def replicated_model()
      write_inheritable_attribute(:replicated, true)
    end
  end
end

ActiveRecord::Base.extend(Octopus::Model)