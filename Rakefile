require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'appraisal'

task :default => :spec

RSpec::Core::RakeTask.new(:spec) do |spec|
end

namespace :db do
  desc 'Build the databases for tests'
  task :build_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"

    sql = (1..5).map do |i|
      "CREATE DATABASE octopus_shard_#{i} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci;"
    end.join

    %x( echo "#{sql}" | mysql -u #{mysql_user} )

    # Postgres
    %x( createdb -E UTF8 -U #{postgres_user} octopus_shard_1 )
  end

  desc 'Drop the tests databases'
  task :drop_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"

    sql = (1..5).map { |i| "DROP DATABASE IF EXISTS octopus_shard_#{i};" }.join

    %x( echo "#{sql}" | mysql -u "#{mysql_user}" )

    %x( dropdb -U #{postgres_user} octopus_shard_1 )
    %x( rm -f /tmp/database.sqlite3 )
  end

  desc 'Create tables on tests databases'
  task :create_tables do
    Dir.chdir(File.expand_path("../spec", __FILE__))

    require "octopus"
    require "support/database_connection"

    [:master, :brazil, :canada, :russia, :alone_shard, :postgresql_shard, :sqlite_shard].each do |shard_symbol|
      # Rails 3.1 needs to do some introspection around the base class, which requires
      # the model be a descendent of ActiveRecord::Base.
      class BlankModel < ActiveRecord::Base; end;

      BlankModel.using(shard_symbol).connection.initialize_schema_migrations_table()

      BlankModel.using(shard_symbol).connection.create_table(:users) do |u|
        u.string :name
        u.integer :number
        u.boolean :admin
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
      end

      BlankModel.using(shard_symbol).connection.create_table(:parts) do |u|
        u.string :name
        u.integer :item_id
      end

      BlankModel.using(shard_symbol).connection.create_table(:yummy) do |u|
        u.string :name
      end
    end
  end

  desc 'Prepare the test databases'
  task :prepare => [:drop_databases, :build_databases, :create_tables]
end
