require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection({:adapter => "mysql", :database => "teste1", :user => "root", :password => ""})

class User < ActiveRecord::Base
  def awesome_queries
    using_shard(:canada) do
      User.create(:name => "teste")
    end
  end
end