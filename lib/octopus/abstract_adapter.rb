# Implementation courtesy of db-charmer.
module Octopus
  module AbstractAdapter
    module OctopusShard
      class InstrumenterDecorator < ActiveSupport::ProxyObject
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

      def octopus_shard
        @config && @config[:octopus_shard]
      end

      def initialize(*args)
        super
        @instrumenter = InstrumenterDecorator.new(self, @instrumenter)
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:prepend, Octopus::AbstractAdapter::OctopusShard)
