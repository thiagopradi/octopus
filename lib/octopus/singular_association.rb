module Octopus::SingularAssociation
  def self.included(base)
    base.sharded_methods :reader, :writer, :create, :create!, :build
  end
end

ActiveRecord::Associations::SingularAssociation.send(:include, Octopus::SingularAssociation)
