module Octopus::AssociationCollection

  METHODS = %w[
    reader
    writer
    ids_reader
    ids_writer
    create
    create!
    build
    any?
    count
    empty?
    first
    include?
    last
    length
    load_target
    many?
    size
    select
    uniq
  ]

  def self.included(base)
    base.instance_eval do
      METHODS.each do |m|
        alias_method_chain m.to_sym, :octopus
      end
    end
  end

  METHODS.each do |m|
    m =~ /([^!?]+)([!?])?/
    method, punctuation = [ $1, $2 ]
    with = :"#{method}_with_octopus#{punctuation}"
    without = :"#{method}_without_octopus#{punctuation}"
    define_method with do |*args, &block|
      @owner.run_on_shard { send(without, *args, &block) }
    end
  end

  def should_wrap_the_connection?
    @owner.respond_to?(:current_shard) && @owner.current_shard != nil
  end

end

ActiveRecord::Associations::CollectionAssociation.send(:include, Octopus::AssociationCollection)
