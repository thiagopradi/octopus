$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "ar-octopus"
    gem.summary = "Easy Database Sharding for ActiveRecord"
    gem.description = "This gem allows you to use sharded databases with ActiveRecord. this also provides a interface for replication and for running migrations with multiples shards."
    gem.email = "tchandy@gmail.com"
    gem.homepage = "http://github.com/tchandy/octopus"
    gem.authors = ["Thiago Pradi", "Mike Perham", "Amit Agarwal"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.version = "0.0.2"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "octopus #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :db do
  desc 'Build the MySQL test databases'
  task :build_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"
    (1..5).each do |idx|
      %x( echo "create DATABASE octopus_shard#{idx} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{mysql_user})
    end
    
    %x( createdb -E UTF8 -U #{postgres_user} octopus_shard1 )
  end

  desc 'Drop the MySQL test databases'
  task :drop_databases do
    mysql_user = ENV['MYSQL_USER'] || "root"
    postgres_user = ENV['POSTGRES_USER'] || "postgres"
    (1..5).each do |idx|
      %x( mysqladmin --user=#{mysql_user} -f drop octopus_shard#{idx} )
    end
    
    %x( dropdb -U #{postgres_user} octopus_shard1 )
  end

  desc 'Create tables on mysql databases'
  task :create_tables do
    Dir.chdir(File.expand_path(File.dirname(__FILE__) + "/spec"))
    require "database_connection"
    require "octopus"
    [:master, :brazil, :canada, :russia, :alone_shard, :postgresql_shard].each do |shard_symbol|
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:users) do |u|
        u.string :name
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
      
      ActiveRecord::Base.using(shard_symbol).connection.create_table(:schema_migrations) do |u|
        u.string :version, :unique => true, :null => false
      end
    end
  end
  
  desc 'Prepare the MySQL test databases'
  task :prepare => [:drop_databases, :build_databases, :create_tables]
end



