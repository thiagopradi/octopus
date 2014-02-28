module Octopus::SingularAssociation
  def self.included(base)
    base.instance_eval do
      alias_method_chain :reader, :octopus
      alias_method_chain :writer, :octopus
      alias_method_chain :create, :octopus
      alias_method_chain :create!, :octopus
      alias_method_chain :build, :octopus
    end
  end

  def reader_with_octopus(*args)
    owner.run_on_shard { reader_without_octopus(*args) }
  end

  def writer_with_octopus(*args)
    owner.run_on_shard { writer_without_octopus(*args) }
  end

  def create_with_octopus(*args)
    owner.run_on_shard { create_without_octopus(*args) }
  end

  def create_with_octopus!(*args)
    owner.run_on_shard { create_without_octopus!(*args) }
  end

  def build_with_octopus(*args)
    owner.run_on_shard { build_without_octopus(*args) }
  end

end

ActiveRecord::Associations::SingularAssociation.send(:include, Octopus::SingularAssociation)