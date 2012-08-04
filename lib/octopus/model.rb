module Octopus::Model
  def self.extended(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.hijack_connection()
    base.hijack_initializer()
  end

  module SharedMethods
    def clean_table_name
      return unless self.connection_proxy.should_clean_table_name?

      if self != ActiveRecord::Base && self.respond_to?(:reset_table_name) && !self.custom_octopus_table_name
        self.reset_table_name()
      end

      if Octopus.rails3?
        self.reset_column_information
        self.instance_variable_set(:@quoted_table_name, nil)
      end
    end

    def using(shard)
      if Octopus.enabled?
        clean_table_name
        Octopus::ScopeProxy.new(shard, self)
      else
        self
      end
    end

    def hijack_initializer()
      attr_accessor :current_shard
      before_save :reload_connection

      def set_current_shard
        if new_record? || self.class.connection_proxy.block
          self.current_shard = self.class.connection_proxy.current_shard
        else
          self.current_shard = self.class.connection_proxy.last_current_shard
        end
      end

      if Octopus.rails3?
        after_initialize :set_current_shard
      else
        def after_initialize
          set_current_shard()
        end
      end
    end

    def hijack_connection()
      def self.should_use_normal_connection?
        !Octopus.enabled? || self.custom_octopus_connection
      end

      def self.connection_proxy
        Thread.current[:connection_proxy] ||= Octopus::Proxy.new
      end

      def self.connection_with_octopus
        if should_use_normal_connection?
          connection_without_octopus
        else
          self.connection_proxy.current_model = self
          self.connection_proxy
        end
      end

      def self.connection_pool_with_octopus
        if should_use_normal_connection?
          connection_pool_without_octopus
        else
          connection_proxy.connection_pool
        end
      end

      class << self
        alias_method_chain :connection, :octopus
        alias_method_chain :connection_pool, :octopus
      end
    end
  end

  module InstanceMethods
    include SharedMethods

    def should_set_current_shard?
      self.respond_to?(:current_shard) && !self.current_shard.nil?
    end

    def reload_connection_safe(&block)
      return yield unless should_set_current_shard?
      original = self.class.connection_proxy.current_shard
      self.class.connection_proxy.current_shard = self.current_shard
      result = yield
      self.class.connection_proxy.current_shard = original
      result
    end

    def reload_connection()
      return unless should_set_current_shard?
      self.class.connection_proxy.current_shard = self.current_shard
    end
  end

  module ClassMethods
    include SharedMethods

    def self.extended(base)
      base.class_attribute(:replicated)
      base.class_attribute(:sharded)
      base.class_attribute(:custom_octopus_connection)
      base.class_attribute(:custom_octopus_table_name)
    end

    def replicated_model
      self.replicated = true
    end

    def sharded_model
      self.sharded = true
    end

    def octopus_establish_connection(spec = nil)
      self.custom_octopus_connection = true
      establish_connection(spec)
    end

    def octopus_set_table_name(value = nil)
      self.custom_octopus_table_name = true
      self.table_name = value
    end
  end
end

ActiveRecord::Base.extend(Octopus::Model)

class OctopusModel < ActiveRecord::Base; end;
