require "logger"

class Octopus::Logger < Logger
  def initialize(logdev, shift_age = 0, shift_size = 1048576)
    ActiveSupport::Deprecation.warn "Octopus::Logger is deprecated and will be removed in Octopus 0.6.x", caller
    super
  end

  def format_message(severity, timestamp, progname, msg)
    str = super

    if ActiveRecord::Base.connection.respond_to?(:current_shard)
      str += "Shard: #{ActiveRecord::Base.connection.current_shard} -"
    end

    str
  end
end

