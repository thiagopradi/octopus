require 'spec_helper'

describe 'when using db2' do
  before(:each) do
    OctopusHelper.clean_connection_proxy
    skip "DB2 support not loaded" unless Octopus.ibm_db_support?
  end

  it 'should create an object' do
    Octopus.using(:db2_shard) do
      Cat.create!(:name => "Kitty")
      expect(Cat.count).to eq(1)
    end
  end

end
