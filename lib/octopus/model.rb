module Octopus::Model  
  def self.extended(base) 
    base.send(:include, InstanceMethods)
  end
  
  module InstanceMethods
    def reload_connection()
      set_connection() if have_a_valid_shard?
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
      set_connection()
      super
    end

    def hijack_initializer()
      attr_accessor :current_shard
      after_initialize :set_current_shard
      before_save :set_connection
      before_destroy :set_connection

      def set_current_shard
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
          Thread.current[:connection_proxy] ||= Octopus::Proxy.new(Octopus.config())
        end

        def connection 
          if self.respond_to?(:replicated)
            self.connection_proxy().set_replicated_model(self)
          end

          self.connection_proxy()
        end
      end
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

    def have_a_valid_shard?
      self.respond_to?(:current_shard) && self.current_shard != nil
    end

    def set_connection(*args)
      if(args.size == 1)
        arg = args.first
        arg.current_shard = self.current_shard if arg.respond_to?(:current_shard) && have_a_valid_shard?
      end

      self.class.connection_proxy.current_shard = self.current_shard if have_a_valid_shard?
    end

    def clean_table_name
      self.reset_table_name() if self != ActiveRecord::Base && self.respond_to?(:reset_table_name)
    end
  end
  
  
  include InstanceMethods

  def replicated_model()
    self.cattr_accessor :replicated
  end
end

ActiveRecord::Base.extend(Octopus::Model)