# Implementation courtesy of db-charmer.
module Octopus
  module AbstractAdapter
    module OctopusShard

      parent = Octopus.rails3? ? ActiveSupport::BasicObject : ActiveSupport::ProxyObject

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
      end

      def octopus_shard
        @config[:octopus_shard]
      end

      def initialize_with_octopus_shard(*args)
        initialize_without_octopus_shard(*args)
        @instrumenter = InstrumenterDecorator.new(self, @instrumenter)
      end

    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, Octopus::AbstractAdapter::OctopusShard)
