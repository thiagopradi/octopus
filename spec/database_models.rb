#The user class is just sharded, not replicated
class User < ActiveRecord::Base
  def awesome_queries
    using(:canada) do
      User.create(:name => "teste")
    end
  end
end

#The client class isn't replicated
class Client < ActiveRecord::Base
  has_many :items, :before_remove => :set_connection, :before_add => :set_connection
end

#This class is replicated
class Cat < ActiveRecord::Base
  replicated_model()
end

#This items belongs to a client
class Item < ActiveRecord::Base
  belongs_to :client
end

class Keyboard < ActiveRecord::Base
  belongs_to :computer
end

class Computer < ActiveRecord::Base
  has_one :keyboard
end

class Role < ActiveRecord::Base
  has_and_belongs_to_many :permissions, :before_remove => :set_connection, :before_add => :set_connection
end

class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles, :before_remove => :set_connection, :before_add => :set_connection
end

class Assignment < ActiveRecord::Base
  belongs_to :programmer
  belongs_to :project
end

class Programmer < ActiveRecord::Base
  has_many :assignments, :before_remove => :set_connection, :before_add => :set_connection
  has_many :projects, :through => :assignments, :before_remove => :set_connection, :before_add => :set_connection
end

class Project < ActiveRecord::Base
  has_many :assignments, :before_remove => :set_connection, :before_add => :set_connection
  has_many :programmers, :through => :assignments, :before_remove => :set_connection, :before_add => :set_connection
end