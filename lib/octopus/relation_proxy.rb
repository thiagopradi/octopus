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

    def respond_to?(*args)
      method_missing(:respond_to?, *args)
    end

    ENUM_METHODS = (::Enumerable.instance_methods - ::Object.instance_methods).reject do |m|
      ::ActiveRecord::Relation.instance_method(m).source_location rescue nil
    end + [:each, :map, :sum, :index_by] # redefined methods in ActiveRecord that should run_on_shard

    def method_missing(method, *args, &block)
      if ENUM_METHODS.include? method
        run_on_shard { @ar_relation.to_a }.public_send(method, *args, &block)
      elsif block
        @ar_relation.public_send(method, *args, &block)
      else
        run_on_shard do
          if method == :load_records
            @ar_relation.send(method, *args)
          else
            @ar_relation.public_send(method, *args)
          end
        end
      end
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
