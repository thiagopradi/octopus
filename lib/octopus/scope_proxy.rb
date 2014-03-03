class Octopus::ScopeProxy
  include Octopus::ShardTracking::Attribute
  attr_accessor :klass

  def initialize(shard, klass)
    @current_shard = shard
    @klass = klass
  end

  def using(shard)
    raise "Nonexistent Shard Name: #{shard}" if @klass.connection.instance_variable_get(:@shards)[shard].nil?
    @current_shard = shard
    return self
  end

  # Transaction Method send all queries to a specified shard.
  def transaction(options = {}, &block)
    run_on_shard { @klass = klass.transaction(options, &block) }
  end

  def connection
    @klass.connection().current_shard = @current_shard
    @klass.connection()
  end

  def method_missing(method, *args, &block)
    result = run_on_shard { @klass.send(method, *args, &block) }

    if result.respond_to?(:scoped)
      @klass = result
      return self
    end

    result
  end

  def as_json(options = nil)
    method_missing(:as_json, options)
  end

  # Delegates to method_missing (instead of @klass) so that User.using(:blah).where(:name => "Mike")
  # gets run in the correct shard context when #== is evaluated.
  def ==(*args)
    method_missing(:==, *args)
  end
  alias :eql? :==
end
