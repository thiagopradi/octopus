require "rubygems"
require "bundler"

Bundler.setup()

require File.expand_path(File.dirname(__FILE__)) + "/database_connection"
require "octopus"
require "octopus_helper"
require "action_controller"
require 'rspec/core'

MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))

RSpec.configure do |config|
  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.dirname(__FILE__))
    require "database_models"
    clean_all_shards()
  end
end
