module Octopus
  module ShardTracking
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # If the class which includes this module responds to the class
      # method sharded_methods, then automagically alias_method_chain
      # a sharding-friendly version of each of those methods into existence
      def sharded_methods(*methods)
        methods.each { |m| create_sharded_method(m) }
      end

      def create_sharded_method(name)
        name.to_s =~ /([^!?]+)([!?])?/
        method, punctuation = [Regexp.last_match[1], Regexp.last_match[2]]
        with = :"#{method}_with_octopus#{punctuation}"
        without = :"#{method}_without_octopus#{punctuation}"
        define_method with do |*args, &block|
          run_on_shard { send(without, *args, &block) }
        end
        alias_method_chain name.to_sym, :octopus
      end
    end

    # Adds run_on_shard method, but does not implement current_shard method
    def run_on_shard(&block)
      if (cs = current_shard)
        r = ActiveRecord::Base.connection_proxy.run_queries_on_shard(cs, &block)
        # Use a case statement to avoid any path through ActiveRecord::Delegation's
        # respond_to? code. We want to avoid the respond_to? code because it can have
        # the side effect of causing a call to load_target
        r = Octopus::RelationProxy.new(cs, r) if ActiveRecord::Relation === r and not Octopus::RelationProxy === r
        r
      else
        yield
      end
    end
  end
end
