class CreateSampleUsers < ActiveRecord::Migration
  using(:master, :asia, :europe, :america)

  def self.up
    User.create!(:name => "Exception")
  end

  def self.down
    User.find_by_name("Exception").delete()
  end
end
