module Octopus
  module Association
    def self.included(base)
      base.send(:include, Octopus::ShardTracking::Dynamic)
    end

    def current_shard
      owner.current_shard
    end
  end
end

ActiveRecord::Associations::Association.send(:include, Octopus::Association)
