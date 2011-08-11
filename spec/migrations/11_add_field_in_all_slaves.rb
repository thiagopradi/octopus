class AddFieldInAllSlaves < ActiveRecord::Migration
  using(:slave1, :slave2, :slave3, :slave4)

  def self.up
    Cat.create!(:name => "Slaves")
  end

  def self.down
    Cat.delete_all()
  end
end