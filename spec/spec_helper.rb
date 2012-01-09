require "rubygems"
require "bundler/setup"
require "mysql"
require "active_record"
require "action_controller"
require "octopus"
require "support/database_connection"
require "support/octopus_helper"

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))

RSpec.configure do |config|
  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.dirname(__FILE__))
    require "support/database_models"
    clean_all_shards()
  end
end

$: << File.expand_path(File.join(File.dirname(__FILE__), "support"))
