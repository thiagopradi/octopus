MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))
require 'spec'
require 'spec/autorun'
require "database_connection"
require "action_pack"
require "action_controller"
require 'octopus'

Spec::Runner.configure do |config|  
  config.mock_with :rspec

  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.dirname(__FILE__))
    require "database_models"
    clean_all_shards()
  end

  config.after(:each) do
    clean_all_shards()
  end
end

def clean_all_shards()
  ActiveRecord::Base.using(:master).connection.shards.keys.each do |shard_symbol|
    ['schema_migrations', 'users', 'clients', 'cats', 'items', 'keyboards', 'computers', 'permissions_roles', 'roles', 'permissions'].each do |tables|
      ActiveRecord::Base.using(shard_symbol).connection.execute("DELETE FROM #{tables};") 
    end
  end
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
    ActiveRecord::Base.class_eval("@@connection_proxy = nil")
    yield
  ensure
    Octopus.instance_variable_set(:@env, 'production')
    ActiveRecord::Base.class_eval("@@connection_proxy = nil")
  end
end