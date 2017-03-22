# Implementation courtesy of db-charmer.
module Octopus
  module LogSubscriber
    attr_accessor :octopus_shard

    def sql(event)
      self.octopus_shard = event.payload[:octopus_shard]
      super
    end

    def debug(msg)
      conn = octopus_shard ? color("[Shard: #{octopus_shard}]", ActiveSupport::LogSubscriber::GREEN, true) : ''
      super(conn + msg)
    end
  end
end

ActiveRecord::LogSubscriber.send(:prepend, Octopus::LogSubscriber)
