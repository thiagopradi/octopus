require 'spec_helper'

describe 'when the database is not entire sharded' do
  before(:each) do
    allow(Octopus).to receive(:env).and_return('not_entire_sharded')
    OctopusHelper.clean_connection_proxy
  end

  it 'should not send all queries to the specified slave' do
    skip
    # User.create!(:name => "Thiago")
    #
    # using_environment :not_entire_sharded do
    #   Octopus.using(:russia) do
    #     User.create!(:name => "Thiago")
    #   end
    # end
    #
    # User.count.should == 2
  end

  it 'should pick the shard based on current_shard when you have a sharded model' do
    Cat.create!(:name => 'Thiago')

    OctopusHelper.using_environment :not_entire_sharded do
      Octopus.using(:russia) do
        Cat.create!(:name => 'Thiago')
      end
    end

    expect(Cat.count).to eq(1)
  end
end
