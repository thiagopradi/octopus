module Octopus::AssociationCollection 
  def self.included(base)
    base.instance_eval do 
      alias_method_chain :count, :octopus
    end
  end
  
  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end

  def count_with_octopus(*args)
    if should_wrap_the_connection?
      @owner.using(@owner.current_shard) { count_without_octopus(args) } 
    else        
      count_without_octopus(args)
    end
  end
end

ActiveRecord::Associations::AssociationCollection.send(:include, Octopus::AssociationCollection)