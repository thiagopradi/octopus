module Octopus::Controller
  def using(shard, &block)
    Octopus.using(shard, &block)
  end
end

ActionController::Base.send(:include, Octopus::Controller) if defined?(ActionController)