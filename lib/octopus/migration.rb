module Octopus::Migration  
  def self.extended(base)
    class << base
      alias_method_chain :migrate, :octopus
      
      def announce(message)
        version = defined?(@version) ? @version : nil

        text = "#{version} #{name}: #{message} - #{get_current_shard}"
        length = [0, 75 - text.length].max
        write "== %s %s" % [text, "=" * length]
      end
    end
  end

  def using(*args, &block)
    Octopus.config()
    ActiveRecord::Base.hijack_connection() if Octopus.octopus_enviroments.include?(Rails.env.to_s)

    if defined?(::Rails) && Octopus.octopus_enviroments.include?(Rails.env.to_s)
      args.each do |shard|
        self.connection().check_schema_migrations(shard)
      end

      self.connection().block = true
      self.connection().current_shard = args        
    end
    
    yield if block_given?

    return self
  end

  def using_group(*args)
    Octopus.config()
    ActiveRecord::Base.hijack_connection() if Octopus.octopus_enviroments.include?(Rails.env.to_s)
    
    if defined?(::Rails) && Octopus.octopus_enviroments.include?(Rails.env.to_s)
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
    groups = conn.instance_variable_get(:@groups)
    
    return migrate_without_octopus(direction) unless conn.is_a?(Octopus::Proxy)
    
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
