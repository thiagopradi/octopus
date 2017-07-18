require 'logger'
require 'pry-byebug'

ActiveRecord::Base.establish_connection(adapter:  'mysql2',
                                        database: 'octopus_shard_1',
                                        username: ENV['MYSQL_USER'] || 'root',
                                        password: ENV['MYSQL_PASS'] || ''
                                       )
ActiveRecord::Base.connection
ActiveRecord::Base.logger = Logger.new(File.open('database.log', 'a'))
