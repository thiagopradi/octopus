module Octopus::Migration  
  def using(*args, &block)
    Octopus.config()

    args.each do |shard|
      if !ActiveRecord::Base.using(shard).connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
        ActiveRecord::Base.using(shard).connection.initialize_schema_migrations_table 
      end
    end

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
    Octopus.config()

    args.each do |group_shard|
      shards = self.connection().instance_variable_get(:@groups)[group_shard] || []

      shards.each do |shard|
        if !ActiveRecord::Base.using(shard).connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name())
          ActiveRecord::Base.using(shard).connection.initialize_schema_migrations_table 
        end
      end
    end

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