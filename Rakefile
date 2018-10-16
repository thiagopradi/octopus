require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'appraisal'

RSpec::Core::RakeTask.new
RuboCop::RakeTask.new

task :default => [:spec]

namespace :db do
  desc 'Build the databases for tests'
  task :build_databases do
    pg_spec = {
      :adapter  => 'postgresql',
      :host     => 'localhost',
      :username => (ENV['POSTGRES_USER'] || 'postgres'),
      :encoding => 'utf8',
    }

    mysql_spec = {
      :adapter  => 'mysql2',
      :host     => 'localhost',
      :username => (ENV['MYSQL_USER'] || 'root'),
      :encoding => 'utf8',
    }

    ` rm -f /tmp/database.sqlite3 `

    require 'active_record'

    # Connects to PostgreSQL
    ActiveRecord::Base.establish_connection(pg_spec.merge('database' => 'postgres', 'schema_search_path' => 'public'))
    (1..2).map do |i|
      # drop the old database (if it exists)
      ActiveRecord::Base.connection.drop_database("octopus_shard_#{i}")
      # create new database
      ActiveRecord::Base.connection.create_database("octopus_shard_#{i}")
    end

    # Connect to MYSQL
    ActiveRecord::Base.establish_connection(mysql_spec)
    (1..5).map do |i|
      # drop the old database (if it exists)
      ActiveRecord::Base.connection.drop_database("octopus_shard_#{i}")
      # create new database
      ActiveRecord::Base.connection.create_database("octopus_shard_#{i}")
    end
  end

  desc 'Create tables on tests databases'
  task :create_tables do
    require 'octopus'
    # Set the octopus variable directory to spec dir, in order to load the config/shards.yml file.
    Octopus.instance_variable_set(:@directory, "#{File.dirname(__FILE__)}/spec/")

    # Require the database connection
    require "#{File.dirname(__FILE__)}/spec/support/database_connection"

    shard_symbols = [:master, :brazil, :canada, :russia, :alone_shard, :postgresql_shard, :sqlite_shard]
    shard_symbols << :protocol_shard
    shard_symbols.each do |shard_symbol|
      # Rails 3.1 needs to do some introspection around the base class, which requires
      # the model be a descendent of ActiveRecord::Base.
      class BlankModel < ActiveRecord::Base; end

      BlankModel.using(shard_symbol).connection.initialize_schema_migrations_table
      BlankModel.using(shard_symbol).connection.initialize_metadata_table if Octopus.atleast_rails50? 

      BlankModel.using(shard_symbol).connection.create_table(:users) do |u|
        u.string :name
        u.integer :number
        u.boolean :admin
        u.datetime :created_at
        u.datetime :updated_at
      end

      BlankModel.using(shard_symbol).connection.create_table(:clients) do |u|
        u.string :country
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:cats) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:items) do |u|
        u.string :name
        u.integer :client_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:computers) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:keyboards) do |u|
        u.string :name
        u.integer :computer_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:roles) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:permissions) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:permissions_roles, :id => false) do |u|
        u.integer :role_id
        u.integer :permission_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:assignments) do |u|
        u.integer :programmer_id
        u.integer :project_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:programmers) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:projects) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:comments) do |u|
        u.string :name
        u.string :commentable_type
        u.integer :commentable_id
        u.boolean :open, default: false
      end

      BlankModel.using(shard_symbol).connection.create_table(:parts) do |u|
        u.string :name
        u.integer :item_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:yummy) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:adverts) do |u|
        u.string :name
      end

      BlankModel.using(shard_symbol).connection.create_table(:custom) do |u|
        u.string :value
      end

      if shard_symbol == :alone_shard
        BlankModel.using(shard_symbol).connection.create_table(:mmorpg_players) do |u|
          u.string :player_name
        end

        BlankModel.using(shard_symbol).connection.create_table(:weapons) do |u|
          u.integer :mmorpg_player_id
          u.string :name
          u.string :hand
        end

        BlankModel.using(shard_symbol).connection.create_table(:skills) do |u|
          u.integer :mmorpg_player_id
          u.integer :weapon_id
          u.string :name
        end
      end
    end
  end

  desc 'Prepare the test databases'
  task :prepare => [:build_databases, :create_tables]
end
