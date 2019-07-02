require 'spec_helper'

describe 'when using db2' do
  before(:each) do
    OctopusHelper.clean_connection_proxy
    skip "DB2 support not loaded" unless Octopus.ibm_db_support?
  end

  it 'should create an object' do
    Octopus.using(:db2_1) do
      Cat.create!(:name => "Test")
      expect(Cat.count).to eq(1)
    end
  end

  it 'should shard with slave groups' do
    OctopusHelper.using_environment :db2_case1 do
      #allow(Octopus).to receive(:env).and_return('db2_case1')
      Octopus.using(:narnia) do 
        Cat.create(:name => "Aslan")
      end
      expect(Cat.using(:narnia).count).to eq(1)

      # first hit round robins to calormen
      expect(Cat.using(:shard => :narnia, :slave_group => :slaves).count).to eq(0)

      # second hit round robins to archenland (shared db with narnia)
      expect(Cat.using(:shard => :narnia, :slave_group => :slaves).count).to eq(1)
    end
  end

  it 'should work with plain shards' do
    OctopusHelper.using_environment :db2_case2 do
      Octopus.using(:narnia) do 
        Cat.create(:name => "Aslan")
        User.create(:name => "Peter")
      end
      Octopus.using(:archenland) do 
        Cat.create(:name => "Aslan")
        User.create(:name => "Shasta")
      end
      Octopus.using(:calormen) do 
        Cat.create(:name => "Aslan")
        User.create(:name => "Tisroc")
      end
      Octopus.using(:telmar) do 
        Cat.create(:name => "Aslan")
        User.create(:name => "Miraz")
      end

      # All shards have the same Cat
      expect( Octopus.using_all { Cat.where(name: "Aslan").first }.count).to eq(4)

      # Each shard has a unique User
      expect(User.using(:narnia).first.name).to eq("Peter")
      expect(User.using(:archenland).first.name).to eq("Shasta")
      expect(User.using(:calormen).first.name).to eq("Tisroc")
      expect(User.using(:telmar).first.name).to eq("Miraz")
    end 
  end
end
