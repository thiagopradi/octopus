module Octopus
  module HasAndBelongsToManyAssociation
    def self.included(base)
      base.sharded_methods :insert_record
    end
  end
end

ActiveRecord::Associations::HasAndBelongsToManyAssociation.send(:include, Octopus::HasAndBelongsToManyAssociation)
