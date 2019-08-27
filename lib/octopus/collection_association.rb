module Octopus
  module CollectionAssociation
    def self.included(base)
      if Octopus.rails51? || Octopus.rails52?
        base.sharded_methods :reader, :writer, :ids_reader, :ids_writer, :create, :create!,
                             :build, :include?,
                             :load_target, :reload, :size, :select
      else
        base.sharded_methods :reader, :writer, :ids_reader, :ids_writer, :create, :create!,
                             :build, :any?, :count, :empty?, :first, :include?, :last, :length,
                             :load_target, :many?, :reload, :size, :select, :uniq
      end
    end
  end
end

ActiveRecord::Associations::CollectionAssociation.send(:include, Octopus::CollectionAssociation)
