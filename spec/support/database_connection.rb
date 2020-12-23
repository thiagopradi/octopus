require 'logger'

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql2', 
  :database => 'octopus_shard_1', 
  :username => "#{ENV['MYSQL_USER'] || 'root'}", 
  :password => "#{ENV['MYSQL_PASSWORD'] || ''}",
  :host => "#{ENV['MYSQL_HOST'] || 'localhost'}"
)

ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
