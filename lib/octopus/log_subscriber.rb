# Implementation courtesy of db-charmer.
module Octopus
  module LogSubscriber
    def self.included(base)
      base.send(:attr_accessor, :octopus_shard)

      base.send :alias_method, :sql_without_octopus_shard, :sql
      base.send :alias_method, :sql, :sql_with_octopus_shard

      base.send :alias_method, :debug_without_octopus_shard, :debug
      base.send :alias_method, :debug, :debug_with_octopus_shard
    end

    def sql_with_octopus_shard(event)
      self.octopus_shard = event.payload[:octopus_shard]
      sql_without_octopus_shard(event)
    end

    def debug_with_octopus_shard(msg)
      conn = octopus_shard ? color("[Shard: #{octopus_shard}]", ActiveSupport::LogSubscriber::GREEN, true) : ''
      debug_without_octopus_shard(conn + msg)
    end
  end
end

ActiveRecord::LogSubscriber.send(:include, Octopus::LogSubscriber)
