module OctopusHelper
  def self.clean_all_shards(shards)
    if shards.nil?
      shards = BlankModel.using(:master).connection.instance_variable_get(:@shards).keys
    end

    shards.each do |shard_symbol|
      ['schema_migrations', 'users', 'clients', 'cats', 'items', 'keyboards', 'computers', 'permissions_roles', 'roles', 'permissions', 'assignments', 'projects', 'programmers', "yummy", 'adverts'].each do |tables|
        BlankModel.using(shard_symbol).connection.execute("DELETE FROM #{tables}")
      end

      if shard_symbol == 'alone_shard'
        ['mmorpg_players', 'weapons', 'skills'].each do |table|
          BlankModel.using(shard_symbol).connection.execute("DELETE FROM #{table}")
        end
      end
    end
  end

  def self.clean_connection_proxy()
    Thread.current["octopus.current_model"] = nil
    Thread.current["octopus.current_shard"] = nil
    Thread.current["octopus.current_group"] = nil
    Thread.current["octopus.current_slave_group"] = nil
    Thread.current["octopus.block"] = nil
    Thread.current["octopus.last_current_shard"] = nil

    ActiveRecord::Base.send(:class_variable_set, '@@connection_proxy', nil)
  end

  def self.migrating_to_version(version, &block)
    migrations_root = File.expand_path(File.join(File.dirname(__FILE__), '..', 'migrations'))

    begin
      ActiveRecord::Migrator.run(:up, migrations_root, version)
      yield
    ensure
      ActiveRecord::Migrator.run(:down, migrations_root, version)
    end
  end

  def self.using_environment(environment, &block)
    begin
      set_octopus_env(environment.to_s)
      clean_connection_proxy()
      yield
    ensure
      set_octopus_env('octopus')
      clean_connection_proxy()
    end
  end

  def self.set_octopus_env(env)
    Octopus.instance_variable_set(:@config, nil)
    Octopus.stub(:env).and_return(env)
  end
end
