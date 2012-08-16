class User < ActiveRecord::Base
  has_many :items
end
