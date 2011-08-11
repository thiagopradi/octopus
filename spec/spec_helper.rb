require "rubygems"
require File.expand_path(File.dirname(__FILE__)) + "/database_connection"
require "bundler/setup"
require "mysql2"
require "active_record"
require "action_controller"
require "octopus"
require "octopus_helper"

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))

RSpec.configure do |config|
  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.dirname(__FILE__))
    require "database_models"
    clean_all_shards()
  end
end
