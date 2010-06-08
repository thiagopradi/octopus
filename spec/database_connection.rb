require 'rubygems'
require 'active_record'
require 'logger'
require "pg"

ActiveRecord::Base.establish_connection(:adapter => "mysql", :database => "octopus_shard1", :username => "root", :password => "")
