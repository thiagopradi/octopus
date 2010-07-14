require "rubygems"
MIGRATIONS_ROOT = File.expand_path(File.join(File.dirname(__FILE__),  'migrations'))

if ENV["VERSION"]
  gem 'activerecord', ENV["VERSION"]
  gem 'activesupport', ENV["VERSION"]
  gem 'actionpack', ENV["VERSION"]
end

require 'spec'
require 'spec/autorun'
require File.expand_path(File.dirname(__FILE__)) + "/database_connection"
require "action_controller"
require 'octopus'
require "octopus_helper"


Spec::Runner.configure do |config|  
  config.before(:each) do
    Octopus.stub!(:directory).and_return(File.dirname(__FILE__))
    require "database_models"
    clean_all_shards()
  end

  config.after(:each) do
    clean_all_shards()
  end
end