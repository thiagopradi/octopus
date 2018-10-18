require 'spec_helper'

describe Octopus::RelationProxy do
  describe 'shard tracking' do
    before :each do
      @client = Client.using(:canada).create!
      @client.items << Item.using(:canada).create!
      @relation = @client.items
    end

    it 'remembers the shard on which a relation was created' do
      expect(@relation.current_shard).to eq(:canada)
    end

    it 'can define collection association with the same name as ancestor private method' do
      @client.comments << Comment.using(:canada).create!(open: true)
      expect(@client.comments.open).to be_a_kind_of(ActiveRecord::Relation)
    end

    it 'can be dumped and loaded' do
      expect(Marshal.load(Marshal.dump(@relation))).to eq @relation
    end

    it 'maintains the current shard when using where.not(...)' do
      where_chain = @relation.where
      expect(where_chain.current_shard).to eq(@relation.current_shard)
      not_relation = where_chain.not("1=0")
      expect(not_relation.current_shard).to eq(@relation.current_shard)
    end

    context 'when a new relation is constructed from the original relation' do
      context 'and a where(...) is used' do
        it 'does not tamper with the original relation' do
          relation = Item.using(:canada).where(id: 1)
          original_sql = relation.to_sql
          new_relation = relation.where(id: 2)
          expect(relation.to_sql).to eq(original_sql)
        end
      end

      context 'and a where.not(...) is used' do
        it 'does not tamper with the original relation' do
          relation = Item.using(:canada).where(id: 1)
          original_sql = relation.to_sql
          new_relation = relation.where.not(id: 2)
          expect(relation.to_sql).to eq(original_sql)
        end
      end
    end

    context 'when comparing to other Relation objects' do
      before :each do
        @relation.reset
      end

      it 'is equal to its clone' do
        expect(@relation).to eq(@relation.clone)
      end
    end

    it "can deliver methods in ActiveRecord::Batches correctly when given a block" do
      expect { @relation.find_each(&:inspect) }.not_to raise_error
    end

    it "can deliver methods in ActiveRecord::Batches correctly as an enumerator" do
      expect { @relation.find_each.each(&:inspect) }.not_to raise_error
    end

    it "can deliver methods in ActiveRecord::Batches correctly as a lazy enumerator" do
      expect { @relation.find_each.lazy.each(&:inspect) }.not_to raise_error
    end

    context 'under Rails 4' do
      it 'is an Octopus::RelationProxy' do
        expect{@relation.ar_relation}.not_to raise_error
      end

      it 'should be able to return its ActiveRecord::Relation' do
        expect(@relation.ar_relation.is_a?(ActiveRecord::Relation)).to be true
      end

      it 'is equal to an identically-defined, but different, RelationProxy' do
        i = @client.items
        expect(@relation).to eq(i)
        expect(@relation.__id__).not_to eq(i.__id__)
      end

      it 'is equal to its own underlying ActiveRecord::Relation' do
        expect(@relation).to eq(@relation.ar_relation)
        expect(@relation.ar_relation).to eq(@relation)
      end
    end

    context 'when no explicit shard context is provided' do
      it 'uses the correct shard' do
        expect(@relation.count).to eq(1)
      end

      it 'lazily evaluates on the correct shard' do
        # Do something to force Client.connection_proxy.current_shard to change
        _some_count = Client.using(:brazil).count
        expect(@relation.select(:client_id).count).to eq(1)
      end
    end

    context 'when an explicit, but different, shard context is provided' do
      it 'uses the correct shard' do
        expect(Item.using(:brazil).count).to eq(0)
        _clients_on_brazil = Client.using(:brazil).all
        Octopus.using(:brazil) do
          expect(@relation.count).to eq(1)
        end
      end

      it 'uses the correct shard in block when method_missing is triggered on CollectionProxy objects' do
        Octopus.using(:brazil) do
          @client.items.each do |item|
            expect(item.current_shard).to eq(:canada)
            expect(ActiveRecord::Base.connection.current_shard).to eq(:brazil)
          end
        end
      end

      it 'lazily evaluates on the correct shard' do
        expect(Item.using(:brazil).count).to eq(0)
        Octopus.using(:brazil) do
          expect(@relation.select(:client_id).count).to eq(1)
        end
      end
    end
  end
end
