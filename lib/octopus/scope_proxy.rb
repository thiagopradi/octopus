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
  
  # Transaction Method send all queries to a specified shard.
  def transaction(options = {}, &block)
    @klass.connection().current_shard = @shard
    @klass.connection().block = true
    
    begin
      @klass.connection().transaction(options, &block)
    ensure
      @klass.connection().block = false    
    end
  end
    
  def connection
    @klass.connection().current_shard = @shard
    @klass.connection()
  end
  
  def method_missing(method, *args, &block)
    @klass.connection().current_shard = @shard
    @klass = @klass.send(method, *args, &block)
    return @klass if @klass.is_a?(ActiveRecord::Base) or @klass.is_a?(Array) or @klass.is_a?(Fixnum) or @klass.nil?
    return self
  end
  
  def ==(other)
    @shard == other.shard
    @klass == other.klass
  end
end