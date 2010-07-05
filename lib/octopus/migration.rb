module Octopus::Migration  
  def using(*args, &block)
    if args.size == 1
      self.connection().block = true
      self.connection().current_shard = args.first
    else
      self.connection().current_shard = args        
    end
    
    args.each do |shard|
      ActiveRecord::Base.using(:shard).connection.initialize_schema_migrations_table
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