# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
User.create!(:name => "Thiago", :email => "thiago@example.com", :password => "123456", :password_confirmation => "123456", :country => "brazil")
User.create!(:name => "Brad", :email => "brad@example.com", :password => "123456", :password_confirmation => "123456", :country => "canada")
User.create!(:name => "Brad", :email => "brad@example.com", :password => "123456", :password_confirmation => "123456", :country => "mexico")

Item.using(:brazil).create!(:name => "Brazil")
Item.using(:canada).create!(:name => "Canada")
Item.using(:mexico).create!(:name => "Mexico")
