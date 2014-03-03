module Octopus::Association
  def self.included(base)
    base.send(:include, Octopus::ShardTracking::Dynamic)
  end

  def current_shard
    owner.current_shard
  end
end

ActiveRecord::Associations::Association.send(:include, Octopus::Association)
