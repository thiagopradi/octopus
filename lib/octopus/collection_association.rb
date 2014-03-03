module Octopus::CollectionAssociation
  def self.included(base)
    base.sharded_methods :reader, :writer, :ids_reader, :ids_writer, :create, :create!,
                         :build, :any?, :count, :empty?, :first, :include?, :last, :length,
                         :load_target, :many?, :reload, :size, :select, :uniq
  end
end

ActiveRecord::Associations::CollectionAssociation.send(:include, Octopus::CollectionAssociation)
