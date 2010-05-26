module Octopus::Migration
  def self.extended(base)
  end
  
  def using(*args)
    
  end
end

ActiveRecord::Migration.extend(Octopus::Migration)