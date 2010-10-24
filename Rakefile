$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH << (File.dirname(__FILE__) + '/spec')
require 'rubygems'
require 'rake'
require 'rake/tasklib'
require "yaml"
require "bundler"
Bundler.setup()

begin
  require 'metric_fu'
  MetricFu::Configuration.run do |config|
    config.metrics  = [:churn,:flay, :flog, :reek, :roodi, :saikuro]
    config.graphs   = [:flog, :flay, :reek, :roodi]
    config.flay     = { :dirs_to_flay => ['spec', 'lib']  }
    config.flog     = { :dirs_to_flog => ['spec', 'lib']  }
    config.reek     = { :dirs_to_reek => ['spec', 'lib']  }
    config.roodi    = { :dirs_to_roodi => ['spec', 'lib'] }
    config.churn    = { :start_date => "1 year ago", :minimum_churn_count => 10}
  end
rescue LoadError
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ar-octopus"
    gem.summary = "Easy Database Sharding for ActiveRecord"
    gem.description = "This gem allows you to use sharded databases with ActiveRecord. this also provides a interface for replication and for running migrations with multiples shards."
    gem.email = "tchandy@gmail.com"
    gem.homepage = "http://github.com/tchandy/octopus"
    gem.authors = ["Thiago Pradi", "Mike Perham"]
    gem.add_development_dependency "rspec", ">= 2.0.0.beta.19"
    gem.add_development_dependency "mysql", ">= 2.8.1"
    gem.add_development_dependency "pg", ">= 0.9.0"
    gem.add_development_dependency "sqlite3-ruby", ">= 1.3.1"
    gem.add_development_dependency "jeweler", ">= 1.4"
    gem.add_development_dependency "actionpack", ">= 2.3"
    gem.add_dependency('activerecord', '>= 2.3')
    gem.version = "0.2.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
end

task :spec => :check_dependencies

task :default => :spec


namespace :db do
  desc 'Build the databases for tests'
  task :build_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"
    (1..5).each do |idx|
      %x( echo "create DATABASE octopus_shard#{idx} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{mysql_user})
    end
    
    %x( createdb -E UTF8 -U #{postgres_user} octopus_shard1 )
  end

  desc 'Drop the tests databases'
  task :drop_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"
    (1..5).each do |idx|
      %x( mysqladmin --user=#{mysql_user} -f drop octopus_shard#{idx} )
    end
    
    %x( dropdb -U #{postgres_user} octopus_shard1 )
    %x(rm /tmp/database.sqlite3)
  end

  desc 'Create tables on tests databases'
  task :create_tables do
    Dir.chdir(File.expand_path(File.dirname(__FILE__) + "/spec"))
    require "database_connection"
    require "octopus"
    [:master, :brazil, :canada, :russia, :alone_shard, :postgresql_shard, :sqlite_shard].each do |shard_symbol|
      ActiveRecord::Base.using(shard_symbol).connection.initialize_schema_migrations_table()
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:users) do |u|
        u.string :name
        u.integer :number
        u.boolean :admin
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:clients) do |u|
        u.string :country
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:cats) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:items) do |u|
        u.string :name
        u.integer :client_id
      end
            
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:computers) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:keyboards) do |u|
        u.string :name
        u.integer :computer_id
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:roles) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:permissions) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:permissions_roles, :id => false) do |u|
        u.integer :role_id
        u.integer :permission_id
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:assignments) do |u|
        u.integer :programmer_id
        u.integer :project_id
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:programmers) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:projects) do |u|
        u.string :name
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:comments) do |u|
        u.string :name
        u.string :commentable_type
        u.integer :commentable_id
      end
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:parts) do |u|
        u.string :name
        u.integer :item_id
      end
    end
  end
  
  desc 'Prepare the test databases'
  task :prepare => [:drop_databases, :build_databases, :create_tables]
end



