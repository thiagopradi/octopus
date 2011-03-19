def clean_all_shards()
  @@shards ||= ActiveRecord::Base.using(:master).connection.instance_variable_get(:@shards).keys
  @@shards.each do |shard_symbol|
    ['schema_migrations', 'users', 'clients', 'cats', 'items', 'keyboards', 'computers', 'permissions_roles', 'roles', 'permissions', 'assignments', 'projects', 'programmers', "yummy"].each do |tables|
      ActiveRecord::Base.using(shard_symbol).connection.execute("DELETE FROM #{tables}") 
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

def using_environment(environment, &block)
  begin
    set_octopus_env(environment.to_s)
    clean_connection_proxy()
    yield
  ensure
    set_octopus_env('octopus')
    clean_connection_proxy()
  end
end

def set_octopus_env(env)
  Octopus.instance_variable_set(:@config, nil)
  Octopus.stub!(:env).and_return(env)
end
