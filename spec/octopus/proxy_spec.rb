require 'spec_helper'

describe Octopus::Proxy do
  let(:proxy) { subject }

  describe 'creating a new instance', :shards => [] do
    it 'should initialize all shards and groups' do
      # FIXME: Don't test implementation details
      expect(proxy.instance_variable_get(:@shards)).to include('canada', 'brazil', 'master', 'sqlite_shard', 'russia', 'alone_shard',
                                                               'aug2009', 'postgresql_shard', 'aug2010', 'aug2011')

      expect(proxy.instance_variable_get(:@shards)).to include('protocol_shard')

      expect(proxy.has_group?('country_shards')).to be true
      expect(proxy.shards_for_group('country_shards')).to include(:canada, :brazil, :russia)

      expect(proxy.has_group?('history_shards')).to be true
      expect(proxy.shards_for_group('history_shards')).to include(:aug2009, :aug2010, :aug2011)
    end

    it 'should initialize the block attribute as false' do
      expect(proxy.block).to be_falsey
    end

    it 'should initialize replicated attribute as false' do
      expect(proxy.instance_variable_get(:@replicated)).to be_falsey
    end

    it 'should work with thiking sphinx' do
      config = proxy.instance_variable_get(:@config)
      expect(config[:adapter]).to eq('mysql2')
      expect(config[:database]).to eq('octopus_shard_1')
      expect(config[:username]).to eq('root')
    end

    it 'should create a set with all adapters, to ensure that is needed to clean the table name.' do
      adapters = proxy.instance_variable_get(:@adapters)
      expect(adapters).to be_kind_of(Set)
      expect(adapters.to_a).to match_array(%w(sqlite3 mysql2 postgresql))
    end

    it 'should respond correctly to respond_to?(:pk_and_sequence_for)' do
      expect(proxy.respond_to?(:pk_and_sequence_for)).to be true
    end

    it 'should respond correctly to respond_to?(:primary_key)' do
      expect(proxy.respond_to?(:primary_key)).to be true
    end

    context 'when an adapter that modifies the config' do
      before { OctopusHelper.octopus_env = 'modify_config' }
      after  { OctopusHelper.octopus_env = 'octopus'       }

      it 'should not fail with missing adapter second time round' do
        skip 'This test was actually failing because of a typo in the error message.'
        Thread.current['octopus.current_shard'] = :modify_config_read

        expect { Octopus::Proxy.new(Octopus.config) }.not_to raise_error

        Thread.current['octopus.current_shard'] = nil
      end
    end

    describe '#should_clean_table_name?' do
      it 'should return true when you have a environment with multiple database types' do
        expect(proxy.should_clean_table_name?).to be true
      end

      context 'when using a environment with a single table name' do
        before(:each) do
          OctopusHelper.octopus_env = 'production_replicated'
        end

        it 'should return false' do
          expect(proxy.should_clean_table_name?).to be false
        end
      end
    end

    describe 'should raise error if you have duplicated shard names' do
      before(:each) do
        OctopusHelper.octopus_env = 'production_raise_error'
      end

      it 'should raise the error' do
        expect { proxy }.to raise_error('You have duplicated shard names!')
      end
    end

    describe "should initialize just the master when you don't have a shards.yml file" do
      before(:each) do
        OctopusHelper.octopus_env = 'crazy_environment'
      end

      it 'should initialize just the master shard' do
        expect(proxy.instance_variable_get(:@shards).keys).to eq(['master'])
      end

      it 'should not initialize replication' do
        expect(proxy.instance_variable_get(:@replicated)).to be_nil
      end
    end
  end

  describe 'when you have a replicated environment' do
    before(:each) do
      OctopusHelper.octopus_env = 'production_replicated'
    end

    it 'should have the replicated attribute as true' do
      expect(proxy.instance_variable_get(:@replicated)).to be true
    end

    it 'should initialize the list of shards' do
      expect(proxy.instance_variable_get(:@slaves_list)).to eq(%w(slave1 slave2 slave3 slave4))
    end
  end

  describe 'when you have a rails application' do
    before(:each) do
      Rails = double
      OctopusHelper.octopus_env = 'octopus_rails'
    end

    after(:each) do
      Object.send(:remove_const, :Rails)
      Octopus.instance_variable_set(:@config, nil)
      Octopus.instance_variable_set(:@rails_env, nil)
      OctopusHelper.clean_connection_proxy
    end

    it 'should initialize correctly octopus common variables for the environments' do
      allow(Rails).to receive(:env).and_return('staging')
      Octopus.instance_variable_set(:@rails_env, nil)
      Octopus.instance_variable_set(:@environments, nil)
      Octopus.config

      expect(proxy.instance_variable_get(:@replicated)).to be true
      expect(Octopus.environments).to eq(%w(staging production))
    end

    it 'should initialize correctly the shards for the staging environment' do
      allow(Rails).to receive(:env).and_return('staging')
      Octopus.instance_variable_set(:@rails_env, nil)
      Octopus.instance_variable_set(:@environments, nil)
      Octopus.config

      expect(proxy.instance_variable_get(:@shards).keys.to_set).to eq(Set.new(%w(slave1 slave2 master)))
    end

    it 'should initialize correctly the shard octopus_shard value for logging' do
      allow(Rails).to receive(:env).and_return('staging')
      Octopus.instance_variable_set(:@rails_env, nil)
      Octopus.instance_variable_set(:@environments, nil)
      Octopus.config

      expect(proxy.instance_variable_get(:@shards)['slave1'].spec.config).to have_key :octopus_shard
    end

    it 'should initialize correctly the shards for the production environment' do
      allow(Rails).to receive(:env).and_return('production')
      Octopus.instance_variable_set(:@rails_env, nil)
      Octopus.instance_variable_set(:@environments, nil)
      Octopus.config

      expect(proxy.instance_variable_get(:@shards).keys.to_set).to eq(Set.new(%w(slave3 slave4 master)))
    end

    describe 'using the master connection', :shards => [:russia, :master]  do
      before(:each) do
        allow(Rails).to receive(:env).and_return('development')
      end

      it 'should use the master connection' do
        user = User.create!(:name => 'Thiago')
        user.name = 'New Thiago'
        user.save
        expect(User.find_by_name('New Thiago')).not_to be_nil
      end

      it 'should work when using using syntax' do
        user = User.using(:russia).create!(:name => 'Thiago')

        user.name = 'New Thiago'
        user.save

        expect(User.using(:russia).find_by_name('New Thiago')).to eq(user)
        expect(User.find_by_name('New Thiago')).to eq(user)
      end

      it 'should work when using blocks' do
        Octopus.using(:russia) do
          @user = User.create!(:name => 'Thiago')
        end

        expect(User.find_by_name('Thiago')).to eq(@user)
      end

      it 'should work with associations' do
        u = Client.create!(:name => 'Thiago')
        i = Item.create(:name => 'Item')
        u.items << i
        u.save
      end
    end
  end

  describe 'returning the correct connection' do
    describe 'should return the shard name' do
      it 'when current_shard is empty' do
        expect(proxy.shard_name).to eq(:master)
      end

      it 'when current_shard is a single shard' do
        proxy.current_shard = :canada
        expect(proxy.shard_name).to eq(:canada)
      end

      it 'when current_shard is more than one shard' do
        proxy.current_shard = [:russia, :brazil]
        expect(proxy.shard_name).to eq(:russia)
      end
    end

    describe 'should return the connection based on shard_name' do
      it 'when current_shard is empty' do
        expect(proxy.select_connection).to eq(proxy.instance_variable_get(:@shards)[:master].connection)
      end

      it 'when current_shard is a single shard' do
        proxy.current_shard = :canada
        expect(proxy.select_connection).to eq(proxy.instance_variable_get(:@shards)[:canada].connection)
      end
    end
  end

  describe 'saving multiple sharded objects at once' do
    before :each do
      @p = MmorpgPlayer.using(:alone_shard).create!(:player_name => 'Thiago')
    end

    subject { @p.save! }

    context 'when the objects are created with #new and saved one at a time' do
      before :each do
        @p.weapons.create!(:name => 'battleaxe', :hand => 'right')
        @p.skills.create!(:name => 'smiting', :weapon => @p.weapons[0])
      end

      it 'should save all associated objects on the correct shard' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when the objects are created with #new and saved at the same time' do
      before :each do
        @p.weapons.new(:name => 'battleaxe', :hand => 'right')
        @p.skills.new(:name => 'smiting', :weapon => @p.weapons[0])
      end

      it 'should save all associated objects on the correct shard' do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe 'connection reuse' do
    before :each do
      @item_brazil_conn = Item.using(:brazil).new(:name => 'Brazil Item').class.connection.select_connection
      @item_canada_conn = Item.using(:canada).new(:name => 'Canada Item').class.connection.select_connection
    end

    it 'reuses connections' do
      expect(Item.using(:brazil).new(:name => 'Another Brazil Item').class.connection.select_connection).to eq(@item_brazil_conn)
      expect(Item.using(:canada).new(:name => 'Another Canada Item').class.connection.select_connection).to eq(@item_canada_conn)
    end

    it 'reuses connections after clear_active_connections! is called' do
      expect(Item.using(:brazil).new(:name => 'Another Brazil Item').class.connection.select_connection).to eq(@item_brazil_conn)
      expect(Item.using(:canada).new(:name => 'Another Canada Item').class.connection.select_connection).to eq(@item_canada_conn)
    end

    it 'creates new connections after clear_all_connections! is called' do
      Item.clear_all_connections!
      expect(Item.using(:brazil).new(:name => 'Another Brazil Item').class.connection.select_connection).not_to eq(@item_brazil_conn)
      expect(Item.using(:canada).new(:name => 'Another Canada Item').class.connection.select_connection).not_to eq(@item_canada_conn)
    end

    it 'is consistent with connected?' do
      expect(Item.connected?).to be true
      expect(ActiveRecord::Base.connected?).to be true

      Item.clear_all_connections!

      expect(Item.connected?).to be false
      expect(ActiveRecord::Base.connected?).to be false
    end
  end
end
