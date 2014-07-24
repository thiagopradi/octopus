require "spec_helper"

describe Octopus::ScopeProxy do
  it "should allow nested queries" do
    @user1 = User.using(:brazil).create!(:name => "Thiago P", :number => 3)
    @user2 = User.using(:brazil).create!(:name => "Thiago", :number => 1)
    @user3 = User.using(:brazil).create!(:name => "Thiago", :number => 2)

    expect(User.using(:brazil).where(:name => "Thiago").where(:number => 4).order(:number).all).to eq([])
    expect(User.using(:brazil).where(:name => "Thiago").using(:canada).where(:number => 2).using(:brazil).order(:number).all).to eq([@user3])
    expect(User.using(:brazil).where(:name => "Thiago").using(:canada).where(:number => 4).using(:brazil).order(:number).all).to eq([])
  end

  it "should raise a exception when trying to send a query to a shard that don't exists" do
    expect { User.using(:dont_exists).all }.to raise_exception("Nonexistent Shard Name: dont_exists")
  end
end
