module Octopus::AssociationCollection
  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end

  def count(*args)
    if should_wrap_the_connection?
      Octopus.using(@owner.current_shard) { super }
    else
      super
    end
  end
end

if ActiveRecord::VERSION::MAJOR >= 3 && ActiveRecord::VERSION::MINOR >=1
  ActiveRecord::Associations::CollectionAssociation.send(:include, Octopus::AssociationCollection)
else
  ActiveRecord::Associations::AssociationCollection.send(:include, Octopus::AssociationCollection)
end
