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
      run_on_shard { @ar_relation.send(method, *args, &block) }
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

    def ===(other)
      case other
      when Octopus::RelationProxy
        method_missing(:==, other.ar_relation)
      else
        method_missing(:==, other)
      end
    end

    def is_a?(klass)
      super || @ar_relation.is_a?(klass)
    end
  end
end

class ActiveRecord::Relation
  class << self
    alias_method :threequals_without_octopus, :===
    def ===(other)
      threequals_without_octopus(other) || (Octopus::RelationProxy === other && self === other.ar_relation)
    end
  end
end

ActiveRecord::Relation.extend(Octopus::RelationProxy::CaseFixer)
