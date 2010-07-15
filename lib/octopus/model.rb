module Octopus::Model  
  def self.extended(base) 
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.hijack_connection()
    
    class << base
      alias_method_chain :connection, :octopus
    end
  end

  module SharedMethods
    def clean_table_name
      self.reset_table_name() if self != ActiveRecord::Base && self.respond_to?(:reset_table_name)
    end

    def using(shard, &block)
      return self if defined?(::Rails) && !Octopus.enviroments.include?(Rails.env.to_s)

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
      before_save :reload_connection

      def set_current_shard
        if new_record? || self.connection.block
          self.current_shard = self.connection.current_shard    
        else
          self.current_shard = self.connection.last_current_shard  
        end
      end

      if !Octopus.rails3?
        def after_initialize
          set_current_shard()
        end
      end
    end

    def hijack_connection()
      def self.connection_proxy
        Thread.current[:connection_proxy] ||= Octopus::Proxy.new(Octopus.config())
      end

      def self.connection_with_octopus()
        if defined?(::Rails) 
          Octopus.config()
          if Octopus.enviroments.include?(Rails.env.to_s)
            self.connection_proxy().current_model = self
            return self.connection_proxy()
          else
            self.connection_without_octopus()
          end
        else
          self.connection_proxy().current_model = self
          return self.connection_proxy()
        end
      end
    end
  end

  module InstanceMethods
    include SharedMethods

    def should_set_current_shard?
      self.respond_to?(:current_shard) && !self.current_shard.nil?
    end

    def reload_connection()
      self.connection.current_shard = self.current_shard() if should_set_current_shard?
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