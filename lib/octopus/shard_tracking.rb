module Octopus::ShardTracking
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
      method, punctuation = [ $1, $2 ]
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
    if !!current_shard
      ActiveRecord::Base.connection_proxy.run_queries_on_shard(current_shard, &block)
    else
      yield
    end
  end
end
