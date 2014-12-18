module Octopus
  class RelationProxy < BasicObject
    include ::Octopus::ShardTracking::Attribute

    module CaseFixer
      def ===(other)
        other = other.ar_relation while ::Octopus::RelationProxy === other
        super
      end
    end

    attr_accessor :ar_relation

    def initialize(shard, ar_relation)
      @current_shard = shard
      @ar_relation = ar_relation
    end

    def method_missing(method, *args, &block)
      run_on_shard { @ar_relation.public_send(method, *args, &block) }
    end

    def ==(other)
      case other
      when ::Octopus::RelationProxy
        method_missing(:==, other.ar_relation)
      else
        method_missing(:==, other)
      end
    end
    alias_method :eql?, :==
  end
end

ActiveRecord::Relation.extend(Octopus::RelationProxy::CaseFixer)
