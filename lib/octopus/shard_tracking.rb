# Adds current_shard as an attribute; provide a default
# implementation of set_current_shard which considers
# only the current ActiveRecord::Base.connection_proxy
module Octopus::ShardTracking
  def self.extended(base)
    base.send(:include, InstanceMethods)
    base.extend(ClassMethods)
    base.track_current_shard
  end

  module InstanceMethods
    def set_current_shard
      return unless Octopus.enabled?

      if ActiveRecord::Base.connection_proxy.block
        self.current_shard = ActiveRecord::Base.connection_proxy.current_shard
      end
    end

    def run_on_shard(&block)
      if self.current_shard
        ActiveRecord::Base.connection_proxy.run_queries_on_shard(self.current_shard, &block)
      else
        yield
      end
    end
  end

  module ClassMethods
    def track_current_shard
      attr_accessor :current_shard

      original_initializer = instance_method(:initialize)
      define_method(:initialize) do |*args, &block|
        result = original_initializer.bind(self).call(*args, &block)
        set_current_shard
        result
      end
    end
  end
end
