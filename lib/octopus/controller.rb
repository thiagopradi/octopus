module Octopus::Controller
  def using(shard, &block)
    ActiveRecord::Base.using(shard, &block)
  end
end

ActionController::Base.send(:include, Octopus::Controller) if defined?(ActionController)