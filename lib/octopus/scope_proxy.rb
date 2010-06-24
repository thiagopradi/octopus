class Octopus::ScopeProxy
  attr_accessor :shard, :klass
  
  def initialize(shard, klass)
    @shard = shard
    @klass = klass
  end
  
  def using(shard, &block)
    @shard = shard
    if block_given?
      @klass.connection.run_queries_on_shard(@shard, &block)
    end
    
    return self
  end
  
  def connection
    @klass.connection().current_shard = @shard
    @klass.connection()
  end
  
  def method_missing(method, *args, &block)
    @klass.connection().current_shard = @shard
    @klass.send(method, *args, &block)
  end
  
  def ==(other)
    @shard == other.shard
    @klass == other.klass
  end
end