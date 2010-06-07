MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))
require 'spec'
require 'spec/autorun'
require "database_connection"
require 'octopus'

Spec::Runner.configure do |config|  
  config.mock_with :rspec

  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.expand_path(File.join(File.dirname(__FILE__), "..")))
    clean_all_shards()
  end

  config.after(:each) do
    clean_all_shards()
  end
end

def clean_all_shards()
  ActiveRecord::Base.connection.shards.keys.each do |shard_symbol|
    if shard_symbol != :postgresql_shard
      ActiveRecord::Base.using(shard_symbol).connection.execute("delete from schema_migrations;")
      ActiveRecord::Base.using(shard_symbol).connection.execute("delete from users;")  
      ActiveRecord::Base.using(shard_symbol).connection.execute("delete from clients;")  
    end
  end
end