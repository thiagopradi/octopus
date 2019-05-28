require 'active_support/deprecation'

module Octopus
  module Model
    def self.extended(base)
      base.send(:include, Octopus::ShardTracking::Attribute)
      base.send(:include, InstanceMethods)
      base.extend(ClassMethods)
    end

    module SharedMethods
      def using(shard)
        if block_given?
          raise Octopus::Exception, <<-EOF
#{name}.using is not allowed to receive a block, it works just like a regular scope.

If you are trying to scope everything to a specific shard, use Octopus.using instead.
          EOF
        end

        if Octopus.enabled?
          Octopus::ScopeProxy.new(shard, self)
        else
          self
        end
      end
    end

    module InstanceMethods
      include SharedMethods

      def self.included(base)
        base.send(:alias_method, :equality_without_octopus, :==)
        base.send(:alias_method, :==, :equality_with_octopus)
        base.send(:alias_method, :eql?, :==)
        base.send(:alias_method, :perform_validations_without_octopus, :perform_validations)
        base.send(:alias_method, :perform_validations, :perform_validations_with_octopus)
      end

      def set_current_shard
        return unless Octopus.enabled?
        shard = self.class.connection_proxy.current_shard
        self.current_shard = shard if self.class.allowed_shard?(shard)
      end

      def init_with(coder)
        obj = super

        return obj unless Octopus.enabled?
        return obj if obj.class.connection_proxy.current_model_replicated?

        current_shard_value = coder['attributes']['current_shard'].value if coder['attributes']['current_shard'].present? && coder['attributes']['current_shard'].value.present?

        coder['attributes'].send(:attributes).send(:values).delete('current_shard')
        coder['attributes'].send(:attributes).send(:delegate_hash).delete('current_shard') rescue NoMethodError

        obj.current_shard = current_shard_value if current_shard_value.present?
        obj
      end

      def should_set_current_shard?
        self.respond_to?(:current_shard) && !current_shard.nil?
      end

      def equality_with_octopus(comparison_object)
        equality_without_octopus(comparison_object) && comparison_object.current_shard.to_s == current_shard.to_s
      end

      def perform_validations_with_octopus(*args)
        if Octopus.enabled? && should_set_current_shard?
          Octopus.using(current_shard) do
            perform_validations_without_octopus(*args)
          end
        else
          perform_validations_without_octopus(*args)
        end
      end
    end

    module ClassMethods
      include SharedMethods

      def self.extended(base)
        base.class_attribute(:replicated)
        base.class_attribute(:sharded)
        base.class_attribute(:allowed_shards)
        base.hijack_methods
      end

      def replicated_model
        self.replicated = true
      end

      def sharded_model
        self.sharded = true
      end

      def allow_shard(*shards)
        self.allowed_shards ||= []
        self.allowed_shards += shards
      end

      def hijack_methods
        after_initialize :set_current_shard

        around_save :run_on_shard, :unless => lambda { self.class.custom_octopus_connection }

        class_attribute :custom_octopus_connection

        class << self
          attr_accessor :custom_octopus_table_name

          alias_method :connection_without_octopus, :connection
          alias_method :connection, :connection_with_octopus

          alias_method :connection_pool_without_octopus, :connection_pool
          alias_method :connection_pool, :connection_pool_with_octopus

          alias_method :clear_all_connections_without_octopus!, :clear_all_connections!
          alias_method :clear_all_connections!, :clear_all_connections_with_octopus!

          alias_method :clear_active_connections_without_octopus!, :clear_active_connections!
          alias_method :clear_active_connections!, :clear_active_connections_with_octopus!

          alias_method :connected_without_octopus?, :connected?
          alias_method :connected?, :connected_with_octopus?

          def table_name=(value = nil)
            self.custom_octopus_table_name = true
            super
          end
        end
      end

      def connection_proxy
        ActiveRecord::Base.class_variable_defined?(:@@connection_proxy) &&
          ActiveRecord::Base.class_variable_get(:@@connection_proxy) ||
          ActiveRecord::Base.class_variable_set(:@@connection_proxy, Octopus::Proxy.new)
      end

      def should_use_normal_connection?
        if !Octopus.enabled?
          true
        elsif custom_octopus_connection
          !connection_proxy.block || !allowed_shard?(connection_proxy.current_shard)
        end
      end

      def allowed_shard?(shard)
        if custom_octopus_connection
          allowed_shards && shard && (allowed_shards.include?(shard.to_s) || allowed_shards.include?(shard.to_sym))
        else
          true
        end
      end

      def connection_with_octopus
        if should_use_normal_connection?
          connection_without_octopus
        else
          connection_proxy.current_model = self
          connection_proxy
        end
      end

      def connection_pool_with_octopus
        if should_use_normal_connection?
          connection_pool_without_octopus
        else
          connection_proxy.connection_pool
        end
      end

      def clear_active_connections_with_octopus!
        if should_use_normal_connection?
          clear_active_connections_without_octopus!
        else
          connection_proxy.clear_active_connections!
        end
      end

      def clear_all_connections_with_octopus!
        if should_use_normal_connection?
          clear_all_connections_without_octopus!
        else
          connection_proxy.clear_all_connections!
        end
      end

      def connected_with_octopus?
        if should_use_normal_connection?
          connected_without_octopus?
        else
          connection_proxy.connected?
        end
      end

      def set_table_name_with_octopus(value = nil, &block)
        self.custom_octopus_table_name = true
        set_table_name_without_octopus(value, &block)
      end

      def octopus_establish_connection(spec = ENV['DATABASE_URL'])
        self.custom_octopus_connection = true if spec
        establish_connection(spec)
      end

      def octopus_set_table_name(value = nil)
        ActiveSupport::Deprecation.warn 'Calling `octopus_set_table_name` is deprecated and will be removed in Octopus 1.0.', caller
        set_table_name(value)
      end
    end
  end
end

ActiveRecord::Base.extend(Octopus::Model)
