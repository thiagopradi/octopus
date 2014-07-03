module Octopus
  module Relation
    def self.included(base)
      base.send(:include, Octopus::ShardTracking::Attribute)
    end
  end
end

ActiveRecord::Relation.send(:include, Octopus::Relation)
