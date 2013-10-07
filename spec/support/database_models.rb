# Rails 3.1 needs to do some introspection around the base class, which requires
# the model be a descendent of ActiveRecord::Base.
class BlankModel < ActiveRecord::Base; end;

#The user class is just sharded, not replicated
class User < ActiveRecord::Base
  scope :thiago, lambda { where(:name => 'Thiago') }

  def awesome_queries
    Octopus.using(:canada) do
      User.create(:name => "teste")
    end
  end
end

#The client class isn't replicated
class Client < ActiveRecord::Base
  has_many :items
  has_many :comments, :as => :commentable
end

#This class is replicated
class Cat < ActiveRecord::Base
  replicated_model()
  #sharded_model()
end

#This class sets its own connection
class CustomConnection < ActiveRecord::Base
  octopus_establish_connection(:adapter => "mysql2", :database => "octopus_shard_2", :username => "root", :password => "")
end

#This items belongs to a client
class Item < ActiveRecord::Base
  belongs_to :client
  has_many :parts
end

class Part < ActiveRecord::Base
  belongs_to :item
end

class Keyboard < ActiveRecord::Base
  replicated_model
  validates_uniqueness_of :name
  belongs_to :computer
end

class Computer < ActiveRecord::Base
  has_one :keyboard
end

class Role < ActiveRecord::Base
  has_and_belongs_to_many :permissions
end

class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles
end

class Assignment < ActiveRecord::Base
  belongs_to :programmer
  belongs_to :project
end

class Programmer < ActiveRecord::Base
  has_many :assignments
  has_many :projects, :through => :assignments
end

class Project < ActiveRecord::Base
  has_many :assignments
  has_many :programmers, :through => :assignments
end

class Comment < ActiveRecord::Base
  belongs_to :commentable, :polymorphic => true
end


class Bacon < ActiveRecord::Base
  self.table_name = 'yummy'
end

class Cheese < ActiveRecord::Base
  self.table_name = 'yummy' 
end

class Ham < ActiveRecord::Base
  self.table_name = 'yummy'
end

#This class sets its own connection
class Advert < ActiveRecord::Base
  establish_connection(:adapter => "postgresql", :database => "octopus_shard_1", :username => ENV["POSTGRES_USER"] || "postgres", :password => "")
end

class MmorpgPlayer < ActiveRecord::Base
  has_many :weapons
  has_many :skills
end

class Weapon < ActiveRecord::Base
  belongs_to :mmorpg_player, :inverse_of => :weapons
  validates  :hand, :uniqueness => { :scope => :mmorpg_player_id }
  validates_presence_of :mmorpg_player
  has_many   :skills
end

class Skill < ActiveRecord::Base
  belongs_to :weapon, :inverse_of => :skills
  belongs_to :mmorpg_player, :inverse_of => :skills

  validates_presence_of :weapon
  validates_presence_of :mmorpg_player
  validates :name, :uniqueness => { :scope => :mmorpg_player_id }
end
