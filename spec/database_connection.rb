require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection({:adapter => "mysql", :database => "teste1", :user => "root", :password => ""})

class User < ActiveRecord::Base
end