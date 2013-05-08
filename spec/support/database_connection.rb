require "logger"

ActiveRecord::Base.establish_connection(:adapter => "mysql2", :database => "octopus_shard_1", :username => "root", :password => "")
ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
