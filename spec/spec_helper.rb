require 'rubygems'
require 'pry'
require 'bundler/setup'
require 'octopus'

Octopus.instance_variable_set(:@directory, File.dirname(__FILE__))

BaseOctopusMigrationClass = (Octopus.rails4? ? ActiveRecord::Migration : ActiveRecord::Migration[ActiveRecord::VERSION::STRING[0..2]])

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.before(:each) do |example|
    OctopusHelper.clean_all_shards(example.metadata[:shards])
  end
end

# Stub allows for writing to slave, which is usually prohibited
def allow_write_to_slave
  allow(
    ActiveRecord::Base.connection_proxy
  ).to receive(:ensure_master_if_replicated).and_wrap_original do
    ActiveRecord::Base.connection_proxy.select_connection
  end
end
