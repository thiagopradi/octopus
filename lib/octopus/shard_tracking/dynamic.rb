require 'octopus/shard_tracking'

module Octopus::ShardTracking::Dynamic
  def self.included(base)
    base.send(:include, Octopus::ShardTracking)
  end
end
