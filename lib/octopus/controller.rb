module Octopus::Controller
  def using(shard, &block)
    ActiveRecord::Base.connection_proxy.run_query_on_shard(shard, &block)
  end
end

ActionController::Base.send(:include, Octopus::Controller) if defined?(ActionController)