# Adds current_shard as an attribute; provide a default
# implementation of set_current_shard which considers
# only the current ActiveRecord::Base.connection_proxy
module Octopus
  module ShardTracking
    module Attribute
      def self.included(base)
        base.send(:include, Octopus::ShardTracking)
      end

      attr_accessor :current_shard

      def set_current_shard
        return unless Octopus.enabled?

        if ActiveRecord::Base.connection_proxy.block
          self.current_shard = ActiveRecord::Base.connection_proxy.current_shard
        end
      end
    end
  end
end
