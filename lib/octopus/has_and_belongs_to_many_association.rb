module Octopus::HasAndBelongsToManyAssociation
  def self.included(base)
    base.instance_eval do
      alias_method_chain :insert_record, :octopus
    end
  end

  def insert_record_with_octopus(record, force = true, validate = true)
    if should_wrap_the_connection?
      Octopus.using(@owner.current_shard) { insert_record_without_octopus(record, force, validate) }
    else
      insert_record_without_octopus(record, force, validate)
    end
  end
end

ActiveRecord::Associations::HasAndBelongsToManyAssociation.send(:include, Octopus::HasAndBelongsToManyAssociation)