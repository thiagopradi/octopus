def clean_all_shards()
  ActiveRecord::Base.using(:master).connection.instance_variable_get(:@shards).keys.each do |shard_symbol|
    ['schema_migrations', 'users', 'clients', 'cats', 'items', 'keyboards', 'computers', 'permissions_roles', 'roles', 'permissions', 'assignments', 'projects', 'programmers'].each do |tables|
      ActiveRecord::Base.using(shard_symbol).connection.execute("DELETE FROM #{tables};") 
    end
  end
end

def clean_connection_proxy()
  Thread.current[:connection_proxy] = nil  
end

def migrating_to_version(version, &block)
  begin
    ActiveRecord::Migrator.run(:up, MIGRATIONS_ROOT, version)
    yield
  ensure
    ActiveRecord::Migrator.run(:down, MIGRATIONS_ROOT, version)
  end
end

def using_enviroment(enviroment, &block)
  begin
    Octopus.instance_variable_set(:@env, enviroment.to_s)
    clean_connection_proxy()
    yield
  ensure
    Octopus.instance_variable_set(:@env, 'octopus')
    clean_connection_proxy()
  end
end