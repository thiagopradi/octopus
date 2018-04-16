require 'spec_helper'

describe 'when the database is replicated' do
  let(:slave_pool) do
    ActiveRecord::Base.connection_proxy.shards['slave1']
  end

  let(:slave_connection) do
    slave_pool.connection
  end

  let(:master_pool) do
    ActiveRecord::Base.connection_proxy.shards['master']
  end

  let(:master_connection) do
    master_pool.connection
  end

  it 'should send all writes/reads queries to master when you have a non replicated model' do
    OctopusHelper.using_environment :production_replicated do
      u = User.create!(:name => 'Replicated')
      expect(User.count).to eq(1)
      expect(User.find(u.id)).to eq(u)
    end
  end

  it 'should send all writes queries to master' do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.find_by_name('Slave Cat')).to be_nil
      Client.create!(:name => 'Slave Client')
      expect(Client.find_by_name('Slave Client')).not_to be_nil
    end
  end

  it 'should allow to create multiple models on the master' do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!([{ :name => 'Slave Cat 1' }, { :name => 'Slave Cat 2' }])
      expect(Cat.find_by_name('Slave Cat 1')).to be_nil
      expect(Cat.find_by_name('Slave Cat 2')).to be_nil
    end
  end

  context 'when updating model' do
    it 'should send writes to master' do
      OctopusHelper.using_environment :replicated_with_one_slave do
        Cat.using(:slave1).create!(:name => 'Cat')
        cat = Cat.find_by_name('Cat')
        cat.name = 'New name'

        expect(master_connection).to receive(:update).and_call_original

        cat.save!
      end
    end
  end

  context 'when querying' do
    it 'Reads from slave' do
      OctopusHelper.using_environment :replicated_with_one_slave do
        expect(master_connection).not_to receive(:select)

        Cat.where(:name => 'Catman2').first
      end
    end
  end

  context 'When record is read from slave' do
    it 'Should write associations to master' do
      OctopusHelper.using_environment :replicated_with_one_slave do
        client = Client.using(:slave1).create!(:name => 'Client')

        client = Client.find(client.id)

        expect(master_connection).to receive(:insert).and_call_original

        client.items.create!(:name => 'Item')
      end
    end
  end


  describe 'When enabling the query cache' do
    include_context 'with query cache enabled' do
      it 'should do the queries with cache' do
        OctopusHelper.using_environment :replicated_with_one_slave do
          cat1 = Cat.using(:master).create!(:name => 'Master Cat 1')
          _ct2 = Cat.using(:master).create!(:name => 'Master Cat 2')
          expect(Cat.using(:master).find(cat1.id)).to eq(cat1)
          expect(Cat.using(:master).find(cat1.id)).to eq(cat1)
          expect(Cat.using(:master).find(cat1.id)).to eq(cat1)

          cat3 = Cat.using(:slave1).create!(:name => 'Slave Cat 3')
          _ct4 = Cat.using(:slave1).create!(:name => 'Slave Cat 4')
          expect(Cat.find(cat3.id).id).to eq(cat3.id)
          expect(Cat.find(cat3.id).id).to eq(cat3.id)
          expect(Cat.find(cat3.id).id).to eq(cat3.id)

          # Rails 5.1 count the cached queries as regular queries.
          # TODO: How we can verify if the queries are using cache on Rails 5.1? - @thiagopradi
          expected_records = Octopus.rails51? || Octopus.rails52? ? 19 : 14

          expect(counter.query_count).to eq(expected_records)
        end
      end
    end
  end

  describe 'When enabling the query cache with slave unavailable' do
    it "should not raise can't connect error" do
      OctopusHelper.using_environment :replicated_with_one_slave_unavailable do
        expect {
          ActiveRecord::Base.connection.enable_query_cache!
        }.to_not raise_error
      end
    end
  end

  it 'should allow #using syntax to send queries to master' do
    Cat.create!(:name => 'Master Cat')

    OctopusHelper.using_environment :production_fully_replicated do
      expect(Cat.using(:master).find_by_name('Master Cat')).not_to be_nil
    end
  end

  it 'should send the count query to a slave' do
    OctopusHelper.using_environment :production_replicated do
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.count).to eq(0)
    end
  end

  def active_support_subscribed(callback, *args, &_block)
    subscriber = ActiveSupport::Notifications.subscribe(*args, &callback)
    yield
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end

describe 'when the database is replicated and the entire application is replicated' do
  before(:each) do
    allow(Octopus).to receive(:env).and_return('production_fully_replicated')
    OctopusHelper.clean_connection_proxy
  end

  it 'should send all writes queries to master' do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.find_by_name('Slave Cat')).to be_nil
      Client.create!(:name => 'Slave Client')
      expect(Client.find_by_name('Slave Client')).to be_nil
    end
  end

  it 'should send all writes queries to master' do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.find_by_name('Slave Cat')).to be_nil
      Client.create!(:name => 'Slave Client')
      expect(Client.find_by_name('Slave Client')).to be_nil
    end
  end

  it 'should work with validate_uniquess_of' do
    Keyboard.create!(:name => 'thiago')

    OctopusHelper.using_environment :production_fully_replicated do
      k = Keyboard.new(:name => 'thiago')
      expect(k.save).to be false
      expect(k.errors.full_messages).to eq(['Name has already been taken'])
    end
  end

  it 'should reset current shard if slave throws an exception' do
    OctopusHelper.using_environment :production_fully_replicated do
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.connection.current_shard).to eql(:master)
      Cat.where(:rubbish => true)
      expect(Cat.connection.current_shard).to eql(:master)
    end
  end

  it 'should reset current shard if slave throws an exception with custom master' do
    OctopusHelper.using_environment :production_fully_replicated do
      Octopus.config[:master_shard] = :slave2
      Cat.create!(:name => 'Slave Cat')
      expect(Cat.connection.current_shard).to eql(:slave2)
      Cat.where(:rubbish => true)
      expect(Cat.connection.current_shard).to eql(:slave2)
      Octopus.config[:master_shard] = nil
    end
  end
end
