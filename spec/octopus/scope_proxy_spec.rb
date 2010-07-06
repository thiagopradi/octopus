require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::ScopeProxy do
  it "should allow nested queries" do
    if Octopus.rails3?
      @user1 = User.using(:brazil).create!(:name => "Thiago P", :number => 3)
      @user2 = User.using(:brazil).create!(:name => "Thiago", :number => 1)
      @user3 = User.using(:brazil).create!(:name => "Thiago", :number => 2)
    
      User.using(:brazil).where(:name => "Thiago").where(:number => 4).order(:number).all.should == []
      User.using(:brazil).where(:name => "Thiago").using(:canada).where(:number => 2).using(:brazil).order(:number).all.should == [@user3]
      User.using(:brazil).where(:name => "Thiago").using(:canada).where(:number => 4).using(:brazil).order(:number).all.should == []
    end
  end
end