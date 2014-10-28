module Octopus
  class ScopeProxy < BasicObject
    include ::Octopus::ShardTracking::Attribute

    module CaseFixer
      def ===(other)
        other = other.klass while ::Octopus::ScopeProxy === other
        super
      end
    end

    attr_accessor :klass

    def initialize(shard, klass)
      @current_shard = shard
      @klass = klass
    end

    def using(shard)
      fail "Nonexistent Shard Name: #{shard}" if @klass.connection.instance_variable_get(:@shards)[shard].nil?
      @current_shard = shard
      self
    end

    # Transaction Method send all queries to a specified shard.
    def transaction(options = {}, &block)
      run_on_shard { @klass = klass.transaction(options, &block) }
    end

    def connection
      @klass.connection_proxy.current_shard = @current_shard

      if @klass.custom_octopus_connection && @klass.allowed_shard?(@current_shard)
        # Force use of proxy, given we called 'using' explicitly to get here
        @klass.connection_proxy.current_model = @klass
        @klass.connection_proxy
      else
        @klass.connection
      end
    end

    def method_missing(method, *args, &block)
      result = run_on_shard { @klass.send(method, *args, &block) }
      if result.respond_to?(:all)
        @klass = result
        return self
      end

      result
    end

    # Delegates to method_missing (instead of @klass) so that User.using(:blah).where(:name => "Mike")
    # gets run in the correct shard context when #== is evaluated.
    def ==(other)
      method_missing(:==, other)
    end
    alias_method :eql?, :==
  end
end

ActiveRecord::Relation.extend(Octopus::ScopeProxy::CaseFixer)
