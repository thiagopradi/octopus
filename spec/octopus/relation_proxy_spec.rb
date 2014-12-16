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

    unless Octopus.rails3?
      it 'can define collection association with the same name as ancestor private method' do
        @client.comments << Comment.using(:canada).create!(open: true)
        expect(@client.comments.open).to be_a_kind_of(ActiveRecord::Relation)
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

    if Octopus.rails4?
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
        Client.using(:brazil) do
          expect(@relation.count).to eq(1)
        end
      end

      it 'lazily evaluates on the correct shard' do
        expect(Item.using(:brazil).count).to eq(0)
        Client.using(:brazil) do
          expect(@relation.select(:client_id).count).to eq(1)
        end
      end
    end
  end
end
