module Octopus
  module CollectionAssociation
    def self.included(base)
      # https://github.com/thiagopradi/octopus/issues/540
      # https://github.com/schovi/octopus/commit/a39612969286891c705384c214d7f1d0c365609f
      if Octopus.atleast_rails51?
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
