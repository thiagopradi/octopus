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
    alias :eql? :==
  end
end
