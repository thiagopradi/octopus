module Octopus::CollectionProxy
  def current_shard
    (respond_to?(:proxy_association) and proxy_association and proxy_association.owner and proxy_association.owner.current_shard) ||
      (respond_to?(:owner) and owner and owner.current_shard) || nil
  end
end

ActiveRecord::Associations::CollectionProxy.send(:include, Octopus::CollectionProxy)
