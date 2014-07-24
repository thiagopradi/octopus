module Octopus
  module CollectionProxy
    def self.included(base)
      base.send(:include, Octopus::ShardTracking::Dynamic)
      base.sharded_methods :any?, :build, :count, :create, :create!, :concat, :delete, :delete_all,
                           :destroy, :destroy_all, :empty?, :find, :first, :include?, :last, :length,
                           :many?, :pluck, :replace, :select, :size, :sum, :to_a, :uniq
    end

    def current_shard
      @association.owner.current_shard
    end
  end
end

ActiveRecord::Associations::CollectionProxy.send(:include, Octopus::CollectionProxy)
