require 'spec_helper'

describe Octopus, :shards => [] do
  describe '#config' do
    it 'should load shards.yml file to start working' do
      expect(Octopus.config).to be_kind_of(HashWithIndifferentAccess)
    end

    describe "when config file doesn't exist" do
      before(:each) do
        allow(Octopus).to receive(:directory).and_return('/tmp')
        Octopus.instance_variable_set(:@config, nil)
      end

      it 'should return an empty HashWithIndifferentAccess' do
        expect(Octopus.config).to eq(HashWithIndifferentAccess.new)
      end
    end
  end

  describe '#directory' do
    it 'should return the directory that contains the shards.yml file' do
      expect(Octopus.directory).to eq(File.expand_path(File.dirname(__FILE__) + '/../'))
    end
  end

  describe '#env' do
    it "should return 'production' when is outside of a rails application" do
      expect(Octopus.env).to eq('octopus')
    end
  end

  describe '#shards=' do
    after(:each) do
      Octopus.instance_variable_set(:@config, nil)
      Octopus::Model.send(:class_variable_set, :@@connection_proxy, nil)
    end

    it 'should permit users to configure shards on initializer files, instead of on a yml file.' do
      expect { User.using(:crazy_shard).create!(:name => 'Joaquim') }.to raise_error

      Octopus.setup do |config|
        config.shards = { :crazy_shard => { :adapter => 'mysql2', :database => 'octopus_shard_5', :username => 'root', :password => '' } }
      end

      expect { User.using(:crazy_shard).create!(:name => 'Joaquim')  }.not_to raise_error
    end
  end

  describe '#setup' do
    it 'should have the default octopus environment as production' do
      expect(Octopus.environments).to eq(['production'])
    end

    it 'should allow the user to configure the octopus environments' do
      Octopus.setup do |config|
        config.environments = [:production, :staging]
      end

      expect(Octopus.environments).to eq(%w(production staging))

      Octopus.setup do |config|
        config.environments = [:production]
      end
    end
  end

  describe '#enabled?' do
    before do
      Rails = double
    end

    after do
      Object.send(:remove_const, :Rails)
    end

    it 'should be if octopus is configured and should hook into current environment' do
      allow(Rails).to receive(:env).and_return('production')

      expect(Octopus).to be_enabled
    end

    it 'should not be if octopus should not hook into current environment' do
      allow(Rails).to receive(:env).and_return('staging')

      expect(Octopus).not_to be_enabled
    end
  end

  describe '#fully_replicated' do
    before do
      OctopusHelper.using_environment :production_replicated do
        OctopusHelper.clean_all_shards([:slave1, :slave2, :slave3, :slave4])
        4.times { |i| User.using(:"slave#{i + 1}").create!(:name => 'Slave User') }
      end
    end

    it 'sends queries to slaves' do
      OctopusHelper.using_environment :production_replicated do
        expect(User.count).to eq(0)
        4.times do |_i|
          Octopus.fully_replicated do
            expect(User.count).to eq(1)
          end
        end
      end
    end

    it 'allows nesting' do
      OctopusHelper.using_environment :production_replicated do
        Octopus.fully_replicated do
          expect(User.count).to eq(1)

          Octopus.fully_replicated do
            expect(User.count).to eq(1)
          end

          expect(User.count).to eq(1)
        end
      end
    end
  end
end
