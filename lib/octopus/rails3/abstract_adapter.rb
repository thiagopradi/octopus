# Implementation courtesy of db-charmer.
module Octopus
  module AbstractAdapter
    module OctopusShard

      parent = ActiveSupport::BasicObject
      if Octopus.rails_40_or_above?
        parent = ActiveSupport::ProxyObject
      end

      class InstrumenterDecorator < parent
        def initialize(adapter, instrumenter)
          @adapter = adapter
          @instrumenter = instrumenter
        end

        def instrument(name, payload = {}, &block)
          payload[:octopus_shard] ||= @adapter.octopus_shard
          @instrumenter.instrument(name, payload, &block)
        end

        def method_missing(meth, *args, &block)
          @instrumenter.send(meth, *args, &block)
        end
      end

      def self.included(base)
        base.alias_method_chain :initialize, :octopus_shard
        base.alias_method_chain :clear_query_cache, :octopus
      end

      def octopus_shard
        @config[:octopus_shard]
      end

      def initialize_with_octopus_shard(*args)
        initialize_without_octopus_shard(*args)
        @instrumenter = InstrumenterDecorator.new(self, @instrumenter)
      end

      # Intercept calls to clear_query_cache and make sure that all
      # query caches on all shards are invalidated, just to be safe.
      def clear_query_cache_with_octopus
        if Octopus.enabled?
          ActiveRecord::Base.connection_proxy.clear_all_query_caches!
        else
          clear_query_cache_without_octopus
        end
      end

    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Octopus::AbstractAdapter::OctopusShard)
