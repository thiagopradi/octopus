module Octopus::Controller
  def using(shard, &block)
    older_shard = ActiveRecord::Base.connection_proxy.current_shard
    ActiveRecord::Base.connection_proxy.block = true
    ActiveRecord::Base.connection_proxy.current_shard = shard
    begin
      yield
    ensure
      ActiveRecord::Base.connection_proxy.block = false
      ActiveRecord::Base.connection_proxy.current_shard = older_shard
    end
  end
end

ActionController::Base.send(:include, Octopus::Controller) if defined?(ActionController)