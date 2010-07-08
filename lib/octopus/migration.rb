module Octopus::Migration  
  def self.extended(base)
    class << base
      alias_method_chain :migrate, :octopus
    end
  end

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

  def send_queries_to_multiple_shards(shards,  direction)
    shards.each do |shard|
      ActiveRecord::Base.using(shard) { ret = migrate_without_octopus(direction) }
    end
  end

  def migrate_with_octopus(direction)
    conn = ActiveRecord::Base.connection
    groups = conn.instance_variable_get(:@groups)
    
    if conn.current_group.is_a?(Array)
      conn.current_group.each do |group|
        send_queries_to_multiple_shards(groups[group], direction)
      end
    elsif conn.current_group.is_a?(Symbol)
      send_queries_to_multiple_shards(groups[conn.current_group], direction)      
    elsif conn.current_shard.is_a?(Array)
      send_queries_to_multiple_shards(conn.current_shard, direction)
    else
      ret = migrate_without_octopus(direction)
    end

    conn.clean_proxy()

    return ret
  end
end

ActiveRecord::Migration.extend(Octopus::Migration)
