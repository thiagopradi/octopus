require 'rubygems'
require 'pry'
require 'bundler/setup'
require 'octopus'

Octopus.instance_variable_set(:@directory, File.dirname(__FILE__))

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.before(:each) do |example|
    OctopusHelper.clean_all_shards(example.metadata[:shards])
  end
end
