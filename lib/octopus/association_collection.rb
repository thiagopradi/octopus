module Octopus::AssociationCollection

  def self.included(base)
    if Octopus.rails31?
      base.instance_eval do
        alias_method_chain :reader, :octopus
        alias_method_chain :writer, :octopus
        alias_method_chain :ids_reader, :octopus
        alias_method_chain :ids_writer, :octopus
        alias_method_chain :create, :octopus
        alias_method_chain :create!, :octopus
        alias_method_chain :build, :octopus
      end
    end
  end

  def build_with_octopus(*args, &block)
    owner.reload_connection
    build_without_octopus(*args, &block)
  end

  def reader_with_octopus(*args)
    owner.reload_connection
    reader_without_octopus(*args)
  end

  def writer_with_octopus(*args)
    owner.reload_connection
    writer_without_octopus(*args)
  end

  def ids_reader_with_octopus(*args)
    owner.reload_connection
    ids_reader_without_octopus(*args)
  end

  def ids_writer_with_octopus(*args)
    owner.reload_connection
    ids_writer_without_octopus(*args)
  end

  def create_with_octopus(*args, &block)
    owner.reload_connection
    create_without_octopus(*args, &block)
  end

  def create_with_octopus!(*args, &block)
    owner.reload_connection
    create_without_octopus!(*args, &block)
  end

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

if Octopus.rails31?
  ActiveRecord::Associations::CollectionAssociation.send(:include, Octopus::AssociationCollection)
else
  ActiveRecord::Associations::AssociationCollection.send(:include, Octopus::AssociationCollection)
end
