module Octopus
  class RelationProxy
    include Octopus::ShardTracking::Attribute

    attr_accessor :ar_relation

    def initialize(shard, ar_relation)
      @current_shard = shard
      @ar_relation = ar_relation
    end

    def method_missing(method, *args, &block)
      run_on_shard { @ar_relation.send(method, *args, &block) }
    end

    def respond_to?(*args)
      super || @ar_relation.respond_to?(*args)
    end

    # these methods are not normally sent to method_missing

    def select(*args, &block)
      method_missing(:select, *args, &block)
    end

    def inspect
      method_missing(:inspect)
    end

    def as_json(options = nil)
      method_missing(:as_json, options)
    end

    def ==(other)
      case other
      when Octopus::RelationProxy
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
