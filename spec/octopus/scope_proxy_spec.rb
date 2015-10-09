require 'spec_helper'

describe Octopus::ScopeProxy do
  it 'should allow nested queries' do
    @user1 = User.using(:brazil).create!(:name => 'Thiago P', :number => 3)
    @user2 = User.using(:brazil).create!(:name => 'Thiago', :number => 1)
    @user3 = User.using(:brazil).create!(:name => 'Thiago', :number => 2)

    expect(User.using(:brazil).where(:name => 'Thiago').where(:number => 4).order(:number).all).to eq([])
    expect(User.using(:brazil).where(:name => 'Thiago').using(:canada).where(:number => 2).using(:brazil).order(:number).all).to eq([@user3])
    expect(User.using(:brazil).where(:name => 'Thiago').using(:canada).where(:number => 4).using(:brazil).order(:number).all).to eq([])
  end

  context 'When array-like-selecting an item in a group' do
    before(:each) do
      User.using(:brazil).create!(:name => 'Evan', :number => 1)
      User.using(:brazil).create!(:name => 'Evan', :number => 2)
      User.using(:brazil).create!(:name => 'Evan', :number => 3)
      @evans = User.using(:brazil).where(:name => 'Evan')
    end

    it 'allows a block to select an item' do
      expect(@evans.select { |u| u.number == 2 }.first.number).to eq(2)
    end
  end

  context 'When selecting a field within a scope' do
    before(:each) do
      User.using(:brazil).create!(:name => 'Evan', :number => 4)
      @evan = User.using(:brazil).where(:name => 'Evan')
    end

    it 'allows single field selection' do
      expect(@evan.select('name').first.name).to eq('Evan')
    end

    it 'allows selection by array' do
      expect(@evan.select(['name']).first.name).to eq('Evan')
    end

    it 'allows multiple selection by string' do
      expect(@evan.select('id, name').first.id).to be_a(Fixnum)
    end

    it 'allows multiple selection by array' do
      expect(@evan.select(%w(id name)).first.id).to be_a(Fixnum)
    end

    if Octopus.rails4?
      it 'allows multiple selection by symbol' do
        expect(@evan.select(:id, :name).first.id).to be_a(Fixnum)
      end

      it 'allows multiple selection by string and symbol' do
        expect(@evan.select(:id, 'name').first.id).to be_a(Fixnum)
      end
    end
  end

  it "should raise a exception when trying to send a query to a shard that don't exists" do
    expect { User.using(:dont_exists).all }.to raise_exception('Nonexistent Shard Name: dont_exists')
  end
end
