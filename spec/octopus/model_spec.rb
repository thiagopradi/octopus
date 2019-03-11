require 'spec_helper'

describe Octopus::Model do
  describe '#using method' do
    it 'raise when Model#using receives a block' do
      expect { User.using(:master) { true } }.to raise_error(Octopus::Exception, /User\.using is not allowed to receive a block/)
    end

    it 'should allow to send a block to the master shard' do
      Octopus.using(:master) do
        User.create!(:name => 'Block test')
      end

      expect(User.using(:master).find_by_name('Block test')).not_to be_nil
    end

    it 'should allow to pass a string as the shard name to a AR subclass' do
      User.using('canada').create!(:name => 'Rafael Pilha')

      expect(User.using('canada').find_by_name('Rafael Pilha')).not_to be_nil
    end

    it 'should allow comparison of a string shard name with symbol shard name' do
      u = User.using('canada').create!(:name => 'Rafael Pilha')
      expect(u).to eq(User.using(:canada).find_by_name('Rafael Pilha'))
    end

    it 'should allow comparison of a symbol shard name with string shard name' do
      u = User.using(:canada).create!(:name => 'Rafael Pilha')
      expect(u).to eq(User.using('canada').find_by_name('Rafael Pilha'))
    end

    it 'should allow to pass a string as the shard name to a block' do
      Octopus.using('canada') do
        User.create!(:name => 'Rafael Pilha')
      end

      expect(User.using('canada').find_by_name('Rafael Pilha')).not_to be_nil
    end

    it 'should allow selecting the shards on scope' do
      User.using(:canada).create!(:name => 'oi')
      expect(User.using(:canada).count).to eq(1)
      expect(User.count).to eq(0)
    end

    it 'should allow selecting the shard using #new' do
      u = User.using(:canada).new
      u.name = 'Thiago'
      u.save

      expect(User.using(:canada).count).to eq(1)
      expect(User.using(:brazil).count).to eq(0)

      u1 = User.new
      u1.name = 'Joaquim'
      u2 = User.using(:canada).new
      u2.name = 'Manuel'
      u1.save
      u2.save

      expect(User.using(:canada).all).to eq([u, u2])
      expect(User.all).to eq([u1])
    end

    it "should allow the #select method to fetch the correct data when using a block" do
      canadian_user = User.using(:canada).create!(:name => 'Rafael Pilha')

      Octopus.using('canada') do
        @all_canadian_user_ids = User.select('id').to_a
      end

      expect(@all_canadian_user_ids).to eq([canadian_user])
    end

    it "should allow objects to be fetch using different blocks - GH #306" do
      canadian_user = User.using(:canada).create!(:name => 'Rafael Pilha')

      Octopus.using(:canada) { @users = User.where('id is not null') }
      Octopus.using(:canada) { @user = @users.first }

      Octopus.using(:canada) { @user2 = User.where('id is not null').first }

      expect(@user).to eq(canadian_user)
      expect(@user2).to eq(canadian_user)
    end

    describe 'multiple calls to the same scope' do
      it 'works with nil response' do
        scope = User.using(:canada)
        expect(scope.count).to eq(0)
        expect(scope.first).to be_nil
      end

      it 'works with non-nil response' do
        user = User.using(:canada).create!(:name => 'oi')
        scope = User.using(:canada)
        expect(scope.count).to eq(1)
        expect(scope.first).to eq(user)
      end
    end

    it 'should select the correct shard' do
      User.using(:canada)
      User.create!(:name => 'oi')
      expect(User.count).to eq(1)
    end

    it 'should ensure that the connection will be cleaned' do
      expect(ActiveRecord::Base.connection.current_shard).to eq(:master)
      expect do
        Octopus.using(:canada) do
          fail 'Some Exception'
        end
      end.to raise_error(RuntimeError)

      expect(ActiveRecord::Base.connection.current_shard).to eq(:master)
    end

    it 'should ensure that the connection will be cleaned with custom master' do
      OctopusHelper.using_environment :octopus do
        Octopus.config[:master_shard] = :brazil
        expect(ActiveRecord::Base.connection.current_shard).to eq(:brazil)
        expect do
          Octopus.using(:canada) do
            fail 'Some Exception'
          end
        end.to raise_error(RuntimeError)

        expect(ActiveRecord::Base.connection.current_shard).to eq(:brazil)
        Octopus.config[:master_shard] = nil
      end
    end

    it 'should allow creating more than one user' do
      User.using(:canada).create([{ :name => 'America User 1' }, { :name => 'America User 2' }])
      User.create!(:name => 'Thiago')
      expect(User.using(:canada).find_by_name('America User 1')).not_to be_nil
      expect(User.using(:canada).find_by_name('America User 2')).not_to be_nil
      expect(User.using(:master).find_by_name('Thiago')).not_to be_nil
    end

    it 'should work when you have a SQLite3 shard' do
      u = User.using(:sqlite_shard).create!(:name => 'Sqlite3')
      expect(User.using(:sqlite_shard).where(name: 'Sqlite3').first).to eq(u)
    end

    it 'should clean #current_shard from proxy when using execute' do
      User.using(:canada).connection.execute('select * from users limit 1;')
      expect(User.connection.current_shard).to eq(:master)
    end

    it 'should clean #current_shard from proxy when using execute' do
      OctopusHelper.using_environment :octopus do
        Octopus.config[:master_shard] = :brazil
        User.using(:canada).connection.execute('select * from users limit 1;')
        expect(User.connection.current_shard).to eq(:brazil)
        Octopus.config[:master_shard] = nil
      end
    end

    it 'should allow scoping dynamically' do
      User.using(:canada).using(:master).using(:canada).create!(:name => 'oi')
      expect(User.using(:canada).using(:master).count).to eq(0)
      expect(User.using(:master).using(:canada).count).to eq(1)
    end

    it 'should allow find inside blocks' do
      @user = User.using(:brazil).create!(:name => 'Thiago')

      Octopus.using(:brazil) do
        expect(User.first).to eq(@user)
      end

      expect(User.using(:brazil).find_by_name('Thiago')).to eq(@user)
    end

    it 'should clean the current_shard after executing the current query' do
      User.using(:canada).create!(:name => 'oi')
      expect(User.count).to eq(0)
    end

    it 'should support both groups and alone shards' do
      _u = User.using(:alone_shard).create!(:name => 'Alone')
      expect(User.using(:alone_shard).count).to eq(1)
      expect(User.using(:canada).count).to eq(0)
      expect(User.using(:brazil).count).to eq(0)
      expect(User.count).to eq(0)
    end

    it 'should work with named scopes' do
      u = User.using(:brazil).create!(:name => 'Thiago')

      expect(User.thiago.using(:brazil).first).to eq(u)
      expect(User.using(:brazil).thiago.first).to eq(u)

      Octopus.using(:brazil) do
        expect(User.thiago.first).to eq(u)
      end
    end

    describe '#current_shard attribute' do
      it 'should store the attribute when you create or find an object' do
        u = User.using(:alone_shard).create!(:name => 'Alone')
        expect(u.current_shard).to eq(:alone_shard)
        User.using(:canada).create!(:name => 'oi')
        u = User.using(:canada).find_by_name('oi')
        expect(u.current_shard).to eq(:canada)
      end

      it 'should store the attribute when you find multiple instances' do
        5.times { User.using(:alone_shard).create!(:name => 'Alone') }

        User.using(:alone_shard).all.each do |u|
          expect(u.current_shard).to eq(:alone_shard)
        end
      end

      it 'should works when you find, and after that, alter that object' do
        alone_user = User.using(:alone_shard).create!(:name => 'Alone')
        _mstr_user = User.using(:master).create!(:name => 'Master')
        alone_user.name = 'teste'
        alone_user.save
        expect(User.using(:master).first.name).to eq('Master')
        expect(User.using(:alone_shard).first.name).to eq('teste')
      end

      it 'should work for the reload method' do
        User.using(:alone_shard).create!(:name => 'Alone')
        u = User.using(:alone_shard).find_by_name('Alone')
        u.reload
        expect(u.name).to eq('Alone')
      end

      it 'should work passing some arguments to reload method' do
        User.using(:alone_shard).create!(:name => 'Alone')
        u = User.using(:alone_shard).find_by_name('Alone')
        u.reload(:lock => true)
        expect(u.name).to eq('Alone')
      end
    end

    describe 'passing a block' do
      it 'should allow queries be executed inside the block, ponting to a specific shard' do
        Octopus.using(:canada) do
          User.create(:name => 'oi')
        end

        expect(User.using(:canada).count).to eq(1)
        expect(User.using(:master).count).to eq(0)
        expect(User.count).to eq(0)
      end

      it 'should allow execute queries inside a model' do
        u = User.new
        u.awesome_queries
        expect(User.using(:canada).count).to eq(1)
        expect(User.count).to eq(0)
      end
    end

    describe 'raising errors' do
      it "should raise a error when you specify a shard that doesn't exist" do
        expect { User.using(:crazy_shard).create!(:name => 'Thiago') }.to raise_error('Nonexistent Shard Name: crazy_shard')
      end
    end

    describe 'equality' do
      let(:canada1) do
        u = User.new
        u.id = 1
        u.current_shard = :canada
        u
      end

      let(:canada1_dup) do
        u = User.new
        u.id = 1
        u.current_shard = :canada
        u
      end

      let(:brazil1) do
        u = User.new
        u.id = 1
        u.current_shard = :brazil
        u
      end

      it 'should work with persisted objects' do
        u = User.using(:brazil).create(:name => 'Mike')
        expect(User.using(:brazil).find_by_name('Mike')).to eq(u)
      end

      it 'should check current_shard when determining equality' do
        expect(canada1).not_to eq(brazil1)
        expect(canada1).to eq(canada1_dup)
      end

      it 'delegates equality check on scopes' do
        u = User.using(:brazil).create!(:name => 'Mike')
        expect(User.using(:brazil).where(:name => 'Mike')).to eq([u])
      end
    end
  end

  describe 'using a postgresql shard' do
    it 'should update the Arel Engine' do
      if Octopus.atleast_rails52?
        expect(User.using(:postgresql_shard).connection.adapter_name).to eq('PostgreSQL')
        expect(User.using(:alone_shard).connection.adapter_name).to eq('Mysql2')
      else 
        expect(User.using(:postgresql_shard).arel_engine.connection.adapter_name).to eq('PostgreSQL')
        expect(User.using(:alone_shard).arel_engine.connection.adapter_name).to eq('Mysql2')
      end
    end

    it 'should works with writes and reads' do
      u = User.using(:postgresql_shard).create!(:name => 'PostgreSQL User')
      expect(User.using(:postgresql_shard).all).to eq([u])
      expect(User.using(:alone_shard).all).to eq([])
    end
  end

  describe 'AR basic methods' do
    it 'establish_connection' do
      expect(CustomConnection.connection.current_database).to eq('octopus_shard_2')
    end

    it 'reuses parent model connection' do
      klass = Class.new(CustomConnection)

      expect(klass.connection).to be klass.connection
    end

    it 'should not mess with custom connection table names' do
      expect(Advert.connection.current_database).to eq('octopus_shard_1')
      Advert.create!(:name => 'Teste')
    end

    it 'increment' do
      _ = User.using(:brazil).create!(:name => 'Teste', :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.increment(:number)
      u.save
      expect(User.using(:brazil).find_by_number(11)).not_to be_nil
    end

    it 'increment!' do
      _ = User.using(:brazil).create!(:name => 'Teste', :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.increment!(:number)
      expect(User.using(:brazil).find_by_number(11)).not_to be_nil
    end

    it 'decrement' do
      _ = User.using(:brazil).create!(:name => 'Teste', :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.decrement(:number)
      u.save
      expect(User.using(:brazil).find_by_number(9)).not_to be_nil
    end

    it 'decrement!' do
      _ = User.using(:brazil).create!(:name => 'Teste', :number => 10)
      u = User.using(:brazil).find_by_number(10)
      u.decrement!(:number)
      expect(User.using(:brazil).find_by_number(9)).not_to be_nil
    end

    it 'toggle' do
      _ = User.using(:brazil).create!(:name => 'Teste', :admin => false)
      u = User.using(:brazil).find_by_name('Teste')
      u.toggle(:admin)
      u.save
      expect(User.using(:brazil).find_by_name('Teste').admin).to be true
    end

    it 'toggle!' do
      _ = User.using(:brazil).create!(:name => 'Teste', :admin => false)
      u = User.using(:brazil).find_by_name('Teste')
      u.toggle!(:admin)
      expect(User.using(:brazil).find_by_name('Teste').admin).to be true
    end

    it 'count' do
      _u = User.using(:brazil).create!(:name => 'User1')
      _v = User.using(:brazil).create!(:name => 'User2')
      _w = User.using(:brazil).create!(:name => 'User3')
      expect(User.using(:brazil).where(:name => 'User2').all.count).to eq(1)
    end

    it 'maximum' do
      _u = User.using(:brazil).create!(:name => 'Teste', :number => 11)
      _v = User.using(:master).create!(:name => 'Teste', :number => 12)

      expect(User.using(:brazil).maximum(:number)).to eq(11)
      expect(User.using(:master).maximum(:number)).to eq(12)
    end

    it 'sum' do
      u = User.using(:brazil).create!(:name => 'Teste', :number => 11)
      v = User.using(:master).create!(:name => 'Teste', :number => 12)

      expect(User.using(:master).sum(:number)).to eq(12)
      expect(User.using(:brazil).sum(:number)).to eq(11)

      expect(User.where(id: v.id).sum(:number)).to eq(12)
      expect(User.using(:brazil).where(id: u.id).sum(:number)).to eq(11)
      expect(User.using(:master).where(id: v.id).sum(:number)).to eq(12)
    end

    describe 'any?' do
      before { User.using(:brazil).create!(:name => 'User1') }

      it 'works when true' do
        scope = User.using(:brazil).where(:name => 'User1')
        expect(scope.any?).to be true
      end

      it 'works when false' do
        scope = User.using(:brazil).where(:name => 'User2')
        expect(scope.any?).to be false
      end
    end

    it 'exists?' do
      @user = User.using(:brazil).create!(:name => 'User1')

      expect(User.using(:brazil).where(:name => 'User1').exists?).to be true
      expect(User.using(:brazil).where(:name => 'User2').exists?).to be false
    end

    describe 'touch' do
      it 'updates updated_at by default' do
        @user = User.using(:brazil).create!(:name => 'User1')
        User.using(:brazil).where(:id => @user.id).update_all(:updated_at => Time.now - 3.months)
        @user.touch
        expect(@user.reload.updated_at.in_time_zone('GMT').to_date).to eq(Time.now.in_time_zone('GMT').to_date)
      end

      it 'updates passed in attribute name' do
        @user = User.using(:brazil).create!(:name => 'User1')
        User.using(:brazil).where(:id => @user.id).update_all(:created_at => Time.now - 3.months)
        @user.touch(:created_at)
        expect(@user.reload.created_at.in_time_zone('GMT').to_date).to eq(Time.now.in_time_zone('GMT').to_date)
      end
    end

    describe '#pluck' do
      before { User.using(:brazil).create!(:name => 'User1') }

      it 'should works from scope proxy' do
        names = User.using(:brazil).pluck(:name)
        expect(names).to eq(['User1'])
        expect(User.using(:master).pluck(:name)).to eq([])
      end
    end

    it 'update_column' do
      @user = User.using(:brazil).create!(:name => 'User1')
      @user2 = User.using(:brazil).find(@user.id)
      @user2.update_column(:name, 'Joaquim Shard Brazil')
      expect(User.using(:brazil).find_by_name('Joaquim Shard Brazil')).not_to be_nil
    end

    it 'update_attributes' do
      @user = User.using(:brazil).create!(:name => 'User1')
      @user2 = User.using(:brazil).find(@user.id)
      @user2.update_attributes(:name => 'Joaquim')
      expect(User.using(:brazil).find_by_name('Joaquim')).not_to be_nil
    end

    it 'using update_attributes inside a block' do
      Octopus.using(:brazil) do
        @user = User.create!(:name => 'User1')
        @user2 = User.find(@user.id)
        @user2.update_attributes(:name => 'Joaquim')
      end

      expect(User.find_by_name('Joaquim')).to be_nil
      expect(User.using(:brazil).find_by_name('Joaquim')).not_to be_nil
    end

    it 'update_attribute' do
      @user = User.using(:brazil).create!(:name => 'User1')
      @user2 = User.using(:brazil).find(@user.id)
      @user2.update_attribute(:name, 'Joaquim')
      expect(User.using(:brazil).find_by_name('Joaquim')).not_to be_nil
    end

    it 'as_json' do
      ActiveRecord::Base.include_root_in_json = false

      Octopus.using(:brazil) do
        User.create!(:name => 'User1')
      end

      user = User.using(:brazil).where(:name => 'User1').first
      expect(user.as_json(:except => [:created_at, :updated_at, :id])).to eq('admin' => nil, 'name' => 'User1', 'number' => nil)
    end

    describe 'transaction' do
      context 'without assigning a database' do
        it 'works as expected' do
          _u = User.create!(:name => 'Thiago')

          expect(User.using(:brazil).count).to eq(0)
          expect(User.using(:master).count).to eq(1)

          User.using(:brazil).transaction do
            expect(User.find_by_name('Thiago')).to be_nil
            User.create!(:name => 'Brazil')
          end

          expect(User.using(:brazil).count).to eq(1)
          expect(User.using(:master).count).to eq(1)
        end
      end

      context 'when assigning a database' do
        it 'works as expected' do
          klass = User.using(:brazil)

          klass.transaction do
            klass.create!(:name => 'Brazil')
          end

          expect(klass.find_by_name('Brazil')).to be_present
        end
      end
    end

    describe "#finder methods" do
      before(:each) do
        @user1 = User.using(:brazil).create!(:name => 'User1')
        @user2 = User.using(:brazil).create!(:name => 'User2')
        @user3 = User.using(:brazil).create!(:name => 'User3')
      end

      it "#find_each should work with a block" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_each do |user|
          result_array << user
        end

        expect(result_array).to eq([@user1, @user2, @user3])
      end

      it "#find_each should work with a where.not(...)" do
        result_array = []

        User.using(:brazil).where.not(:name => 'User2').find_each do |user|
          result_array << user
        end

        expect(result_array).to eq([@user1, @user3])
      end

      it "#find_each should work as an enumerator" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_each.each do |user|
          result_array << user
        end

        expect(result_array).to eq([@user1, @user2, @user3])
      end

      it "#find_each should work as a lazy enumerator" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_each.lazy.each do |user|
          result_array << user
        end

        expect(result_array).to eq([@user1, @user2, @user3])
      end

      it "#find_in_batches should work with a block" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_in_batches(batch_size: 1) do |user|
          result_array << user
        end

        expect(result_array).to eq([[@user1], [@user2], [@user3]])
      end

      it "#find_in_batches should work as an enumerator" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_in_batches(batch_size: 1).each do |user|
          result_array << user
        end

        expect(result_array).to eq([[@user1], [@user2], [@user3]])
      end

      it "#find_in_batches should work as a lazy enumerator" do
        result_array = []

        User.using(:brazil).where("name is not NULL").find_in_batches(batch_size: 1).lazy.each do |user|
          result_array << user
        end

        expect(result_array).to eq([[@user1], [@user2], [@user3]])
      end
    end

    describe 'deleting a record' do
      before(:each) do
        @user = User.using(:brazil).create!(:name => 'User1')
        @user2 = User.using(:brazil).find(@user.id)
      end

      it 'delete' do
        @user2.delete
        expect { User.using(:brazil).find(@user2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "delete within block shouldn't lose shard" do
        Octopus.using(:brazil) do
          @user2.delete
          @user3 = User.create(:name => 'User3')

          expect(User.connection.current_shard).to eq(:brazil)
          expect(User.find(@user3.id)).to eq(@user3)
        end
      end

      it 'destroy' do
        @user2.destroy
        expect { User.using(:brazil).find(@user2.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "destroy within block shouldn't lose shard" do
        Octopus.using(:brazil) do
          @user2.destroy
          @user3 = User.create(:name => 'User3')

          expect(User.connection.current_shard).to eq(:brazil)
          expect(User.find(@user3.id)).to eq(@user3)
        end
      end
    end
  end

  describe 'custom connection' do
    context 'by default' do
      it 'with plain call should use custom connection' do
        expect(CustomConnection.connection.current_database).to eq('octopus_shard_2')
      end

      it 'should ignore using called on relation' do
        expect(CustomConnection.using(:postgresql_shard).connection.current_database).to eq('octopus_shard_2')
      end

      it 'should ignore Octopus.using block' do
        Octopus.using(:postgresql_shard) do
          expect(CustomConnection.connection.current_database).to eq('octopus_shard_2')
        end
      end

      it 'should save to correct shard' do
        expect { CustomConnection.create(:value => 'custom value') }.to change {
          CustomConnection
            .connection
            .execute("select count(*) as ct from custom where value = 'custom value'")
            .to_a.first.first
        }.by 1
      end
    end

    context 'with allowed_shards configured' do
      before do
        CustomConnection.allow_shard :postgresql_shard
      end

      it 'with plain call should use custom connection' do
        expect(CustomConnection.connection.current_database).to eq('octopus_shard_2')
      end

      it 'with using called on relation with allowed shard should use' do
        expect(CustomConnection.using(:postgresql_shard).connection.current_database).to eq('octopus_shard_1')
      end

      it 'within Octopus.using block with allowed shard should use' do
        Octopus.using(:postgresql_shard) do
          expect(CustomConnection.connection.current_database).to eq('octopus_shard_1')
        end
      end

      it 'with using called on relation with disallowed shard should not use' do
        expect(CustomConnection.using(:brazil).connection.current_database).to eq('octopus_shard_2')
      end

      it 'within Octopus.using block with disallowed shard should not use' do
        Octopus.using(:brazil) do
          expect(CustomConnection.connection.current_database).to eq('octopus_shard_2')
        end
      end

      it 'should save to correct shard' do
        expect { CustomConnection.create(:value => 'custom value') }.to change {
          CustomConnection
            .connection
            .execute("select count(*) as ct from custom where value = 'custom value'")
            .to_a.first.first
        }.by 1
      end

      it 'should clean up correctly' do
        User.create!(:name => 'CleanUser')
        CustomConnection.using(:postgresql_shard).first
        expect(User.first).not_to be_nil
      end

      it 'should clean up correctly even inside block' do
        User.create!(:name => 'CleanUser')

        Octopus.using(:master) do
          CustomConnection.using(:postgresql_shard).connection.execute('select count(*) from users')
          expect(User.first).not_to be_nil
        end
      end
    end

    describe 'clear_active_connections!' do
      it 'should not leak connection' do
        CustomConnection.create(:value => 'custom value')

        # This is what Rails, Sidekiq etc call--this normally handles all connection pools in the app
        expect { ActiveRecord::Base.clear_active_connections! }
          .to change { CustomConnection.connection_pool.active_connection? }

        expect(CustomConnection.connection_pool.active_connection?).to be_falsey
      end
    end
  end

  describe 'when using set_table_name' do
    it 'should work correctly' do
      Bacon.using(:brazil).create!(:name => 'YUMMMYYYY')
    end

    it 'should work correctly with a block' do
      Cheese.using(:brazil).create!(:name => 'YUMMMYYYY')
    end
  end

  describe 'when using table_name=' do
    it 'should work correctly' do
      Ham.using(:brazil).create!(:name => 'YUMMMYYYY')
    end
  end

  describe 'when using a environment with a single adapter' do
    it 'should not clean the table name' do
      OctopusHelper.using_environment :production_fully_replicated do
        expect(Keyboard).not_to receive(:reset_table_name)
        Keyboard.using(:master).create!(:name => 'Master Cat')
      end
    end
  end

  describe 'when you have joins/include' do
    before(:each) do
      @client1 = Client.using(:brazil).create(:name => 'Thiago')

      Octopus.using(:canada) do
        @client2 = Client.create(:name => 'Mike')
        @client3 = Client.create(:name => 'Joao')
        @item1 = Item.create(:client => @client2, :name => 'Item 1')
        @item2 = Item.create(:client => @client2, :name => 'Item 2')
        @item3 = Item.create(:client => @client3, :name => 'Item 3')
        @part1 = Part.create(:item => @item1, :name => 'Part 1')
        @part2 = Part.create(:item => @item1, :name => 'Part 2')
        @part3 = Part.create(:item => @item2, :name => 'Part 3')
      end

      @item4 = Item.using(:brazil).create(:client => @client1, :name => 'Item 4')
    end

    it 'should work using the rails 3.x syntax' do
      items = Item.using(:canada).joins(:client).where("clients.id = #{@client2.id}").all
      expect(items).to eq([@item1, @item2])
    end

    it 'should work for include also, rails 3.x syntax' do
      items = Item.using(:canada).includes(:client).where(:clients => { :id => @client2.id }).all
      expect(items).to eq([@item1, @item2])
    end
  end

  describe 'ActiveRecord::Base Validations' do
    it 'should work correctly when using validations' do
      @key = Keyboard.create!(:name => 'Key')
      expect { Keyboard.using(:brazil).create!(:name => 'Key') }.not_to raise_error
      expect { Keyboard.create!(:name => 'Key') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'should work correctly when using validations with using syntax' do
      @key = Keyboard.using(:brazil).create!(:name => 'Key')
      expect { Keyboard.create!(:name => 'Key') }.not_to raise_error
      expect { Keyboard.using(:brazil).create!(:name => 'Key') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#replicated_model method' do
    it 'should be replicated' do
      OctopusHelper.using_environment :production_replicated do
        expect(ActiveRecord::Base.connection_proxy.replicated).to be true
      end
    end

    it 'should mark the Cat model as replicated' do
      OctopusHelper.using_environment :production_replicated do
        expect(User.replicated).to be_falsey
        expect(Cat.replicated).to be true
      end
    end

    it "should work on a fully replicated environment" do
      OctopusHelper.using_environment :production_fully_replicated do
        User.using(:slave1).create!(name: 'Thiago')
        User.using(:slave2).create!(name: 'Thiago')

        replicated_cat = User.find_by_name 'Thiago'

        expect(replicated_cat.current_shard.to_s).to match(/master/)
      end
    end
  end
end
