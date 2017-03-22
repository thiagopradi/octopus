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
        prepended_module = Module.new do
          methods.each do |method_name|
            define_method method_name do |*args, &block|
              run_on_shard { super(*args, &block) }
            end
          end
        end

        self.send(:prepend, prepended_module)
      end
    end

    # Adds run_on_shard method, but does not implement current_shard method
    def run_on_shard(&block)
      if (cs = current_shard)
        r = ActiveRecord::Base.connection_proxy.run_queries_on_shard(cs, &block)
        # Use a case statement to avoid any path through ActiveRecord::Delegation's
        # respond_to? code. We want to avoid the respond_to? code because it can have
        # the side effect of causing a call to load_target

        if (ActiveRecord::Relation === r || ActiveRecord::QueryMethods::WhereChain === r) && !(Octopus::RelationProxy === r)
          Octopus::RelationProxy.new(cs, r)
        else
          r
        end
      else
        yield
      end
    end
  end
end
