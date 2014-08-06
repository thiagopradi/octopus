require 'octopus/shard_tracking'

module Octopus
  module ShardTracking
    module Dynamic
      def self.included(base)
        base.send(:include, Octopus::ShardTracking)
      end
    end
  end
end
