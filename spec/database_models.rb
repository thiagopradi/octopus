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
end

#This class is replicated
class Cat < ActiveRecord::Base
  replicated_model()
end
