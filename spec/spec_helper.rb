$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'spec'
require 'spec/autorun'
require "database_connection"
require "database_cleaner"
MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))

Spec::Runner.configure do |config|  
  config.before(:each) do
    clean_all_shards()    
  end

  config.after(:each) do
    clean_all_shards()
  end
end

def clean_all_shards()
  ActiveRecord::Base.using(:master).connection.execute("delete from schema_migrations;")
  ActiveRecord::Base.using(:master).connection.execute("delete from users;")
  ActiveRecord::Base.using(:canada).connection.execute("delete from schema_migrations;")
  ActiveRecord::Base.using(:canada).connection.execute("delete from users;")
end

require 'octopus'