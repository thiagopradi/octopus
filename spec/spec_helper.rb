MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))
require 'spec'
require 'spec/autorun'
require "spec/database_connection"
require "action_pack"
require "action_controller"
require 'octopus'
require "octopus_helper"

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