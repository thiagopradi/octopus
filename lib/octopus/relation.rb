require 'octopus/shard_tracking'

module Octopus::Relation
  def self.extended(base)
    base.extend(Octopus::ShardTracking)
  end
end

ActiveRecord::Relation.extend(Octopus::Relation)
