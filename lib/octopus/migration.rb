module Octopus::Migration  
  def self.extended(base)
    class << base
      alias_method_chain :migrate, :octopus
    end
  end

  def using(*args, &block)
    Octopus.config()

    args.each do |shard|
      self.connection().check_schema_migrations(shard)
    end

    self.connection().block = true
    self.connection().current_shard = args        

    yield if block_given?

    return self
  end

  def using_group(*args)
    Octopus.config()
    
    args.each do |group_shard|
      shards = self.connection().instance_variable_get(:@groups)[group_shard] || []

      shards.each do |shard|
        self.connection().check_schema_migrations(shard)
      end
    end

    self.connection().block = true
    self.connection().current_group = args

    return self
  end

  def migrate_with_octopus(direction)
    conn = ActiveRecord::Base.connection
    groups = conn.instance_variable_get(:@groups)
    
    if conn.current_group.is_a?(Array)
      conn.current_group.each { |group| conn.send_queries_to_multiple_shards(groups[group]) { migrate_without_octopus(direction) } } 
    elsif conn.current_group.is_a?(Symbol)       
      conn.send_queries_to_multiple_shards(groups[conn.current_group]) { migrate_without_octopus(direction) }     
    elsif conn.current_shard.is_a?(Array)
      conn.send_queries_to_multiple_shards(conn.current_shard) { migrate_without_octopus(direction) }     
    else
      migrate_without_octopus(direction)
    end

    conn.clean_proxy()
  end
end

ActiveRecord::Migration.extend(Octopus::Migration)
