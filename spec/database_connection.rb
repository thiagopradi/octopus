require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "octopus_shard1", :username => "root", :password => "")
