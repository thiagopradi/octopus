require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => "/Users/tchandy/Projetos/octopus/spec/db/master.db")

class User < ActiveRecord::Base
end