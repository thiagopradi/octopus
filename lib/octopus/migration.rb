module Octopus::Migration  
  def self.extended(base)
    class << base
      def announce_with_octopus(message)
        announce_without_octopus("#{message} - #{get_current_shard}")
      end
      
      alias_method_chain :migrate, :octopus
      alias_method_chain :announce, :octopus
    end
  end

  def using(*args, &block)
    if self.connection().is_a?(Octopus::Proxy) && !block_given?
      args.each do |shard|
        self.connection().check_schema_migrations(shard)
      end

      self.connection().block = true
      self.connection().current_shard = args        
    end
    
    if block_given?
      self.connection.run_queries_on_shard(args, &block)
    end 

    return self
  end

  def using_group(*args)
    if self.connection().is_a?(Octopus::Proxy)
      args.each do |group_shard|
        shards = self.connection().instance_variable_get(:@groups)[group_shard] || []

        shards.each do |shard|
          self.connection().check_schema_migrations(shard)
        end
      end

      self.connection().block = true
      self.connection().current_group = args
    end
    
    return self
  end
  
  def get_current_shard
    "Shard: #{ActiveRecord::Base.connection.current_shard()}" if ActiveRecord::Base.connection.respond_to?(:current_shard)
  end


  def migrate_with_octopus(direction)
    conn = ActiveRecord::Base.connection
    return migrate_without_octopus(direction) unless conn.is_a?(Octopus::Proxy)

    groups = conn.instance_variable_get(:@groups)
    
    begin
      if conn.current_group.is_a?(Array)
        conn.current_group.each { |group| conn.send_queries_to_multiple_shards(groups[group]) { migrate_without_octopus(direction) } } 
      elsif conn.current_group.is_a?(Symbol)       
        conn.send_queries_to_multiple_shards(groups[conn.current_group]) { migrate_without_octopus(direction) }     
      elsif conn.current_shard.is_a?(Array)
        conn.send_queries_to_multiple_shards(conn.current_shard) { migrate_without_octopus(direction) }     
      else
        migrate_without_octopus(direction)
      end
    ensure
      conn.clean_proxy()
    end
  end
end

ActiveRecord::Migration.extend(Octopus::Migration)
