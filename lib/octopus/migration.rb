module Octopus::Migration  
  def using(*args, &block)
    if args.size == 1
      self.connection().block = true
      self.connection().current_shard = args.first
    else
      self.connection().current_shard = args        
    end
    
    yield if block_given?

    return self
  end

  def using_group(*args)
    if args.size == 1
      self.connection().block = true
      self.connection().current_group = args.first
    else
      self.connection().current_group = args
    end

    return self
  end
end


ActiveRecord::Migration.extend(Octopus::Migration)