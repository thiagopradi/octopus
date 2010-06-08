#The user class is sharded
class User < ActiveRecord::Base
  replicated_model()
  
  def awesome_queries
    using_shard(:canada) do
      User.create(:name => "teste")
    end
  end
end

#The client class isn't sharded
class Client < ActiveRecord::Base
end
