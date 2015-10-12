module Octopus
  module Association
    def self.included(base)
      base.send(:include, Octopus::ShardTracking::Dynamic)
      base.sharded_methods :target_scope
    end

    def current_shard
      owner.current_shard
    end
  end
end

ActiveRecord::Associations::Association.send(:include, Octopus::Association)
