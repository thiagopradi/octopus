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
  has_many :items
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