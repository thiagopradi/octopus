require 'spec_helper'

describe Octopus::AssociationShardTracking, :shards => [:brazil, :master, :canada] do
  describe 'when you have a 1 x 1 relationship' do
    before(:each) do
      @computer_brazil = Computer.using(:brazil).create!(:name => 'Computer Brazil')
      @computer_master = Computer.create!(:name => 'Computer Brazil')
      @keyboard_brazil = Keyboard.using(:brazil).create!(:name => 'Keyboard Brazil', :computer => @computer_brazil)
      @keyboard_master = Keyboard.create!(:name => 'Keyboard Master', :computer => @computer_master)
    end

    it 'should find the models' do
      expect(@keyboard_master.computer).to eq(@computer_master)
      expect(@keyboard_brazil.computer).to eq(@computer_brazil)
    end

    it 'should read correctly the relationed model' do
      new_computer_brazil = Computer.using(:brazil).create!(:name => 'New Computer Brazil')
      _new_computer_hello = Computer.create!(:name => 'New Computer Brazil')
      @keyboard_brazil.computer = new_computer_brazil
      @keyboard_brazil.save
      @keyboard_brazil.reload
      expect(@keyboard_brazil.computer_id).to eq(new_computer_brazil.id)
      expect(@keyboard_brazil.computer).to eq(new_computer_brazil)
      new_computer_brazil.save
      new_computer_brazil.reload
      expect(new_computer_brazil.keyboard).to eq(@keyboard_brazil)
    end

    it 'should work when using #build_computer or #build_keyboard' do
      c = Computer.using(:brazil).create!(:name => 'Computer Brazil')
      k = c.build_keyboard(:name => 'Building keyboard')
      c.save
      k.save
      expect(c.keyboard).to eq(k)
      expect(k.computer_id).to eq(c.id)
      expect(k.computer).to eq(c)
    end

    it 'should work when using #create_computer or #create_keyboard' do
      c = Computer.using(:brazil).create!(:name => 'Computer Brazil')
      k = c.create_keyboard(:name => 'Building keyboard')
      c.save
      k.save
      expect(c.keyboard).to eq(k)
      expect(k.computer_id).to eq(c.id)
      expect(k.computer).to eq(c)
    end

    it 'should include models' do
      c = Computer.using(:brazil).create!(:name => 'Computer Brazil')
      k = c.create_keyboard(:name => 'Building keyboard')
      c.save
      k.save

      expect(Computer.using(:brazil).includes(:keyboard).find(c.id)).to eq(c)
    end
  end

  describe 'when you have a N x N relationship' do
    before(:each) do
      @brazil_role = Role.using(:brazil).create!(:name => 'Brazil Role')
      @master_role = Role.create!(:name => 'Master Role')
      @permission_brazil = Permission.using(:brazil).create!(:name => 'Brazil Permission')
      @permission_master = Permission.using(:master).create!(:name => 'Master Permission')
      @brazil_role.permissions << @permission_brazil
      @brazil_role.save
      Client.using(:master).create!(:name => 'teste')
    end

    it 'should find all models in the specified shard' do
      expect(@brazil_role.permission_ids).to eq([@permission_brazil.id])
      expect(@brazil_role.permissions).to eq([@permission_brazil])

      expect(@brazil_role.permissions.first).to eq(@permission_brazil)
      expect(@brazil_role.permissions.last).to eq(@permission_brazil)
    end

    it 'should finds the client that the item belongs' do
      expect(@permission_brazil.role_ids).to eq([@brazil_role.id])
      expect(@permission_brazil.roles).to eq([@brazil_role])

      expect(@permission_brazil.roles.first).to eq(@brazil_role)
      expect(@permission_brazil.roles.last).to eq(@brazil_role)
    end

    it 'should update the attribute for the item' do
      new_brazil_role = Role.using(:brazil).create!(:name => 'new Role')
      @permission_brazil.roles = [new_brazil_role]
      expect(@permission_brazil.roles).to eq([new_brazil_role])
      @permission_brazil.save
      @permission_brazil.reload
      expect(@permission_brazil.role_ids).to eq([new_brazil_role.id])
      expect(@permission_brazil.roles).to eq([new_brazil_role])
    end

    it 'should works for build method' do
      new_brazil_role = Role.using(:brazil).create!(:name => 'Brazil Role')
      c = new_brazil_role.permissions.create(:name => 'new Permission')
      c.save
      new_brazil_role.save
      expect(c.roles).to eq([new_brazil_role])
      expect(new_brazil_role.permissions).to eq([c])
    end

    describe 'it should works when using' do
      before(:each) do
        @permission_brazil_2 = Permission.using(:brazil).create!(:name => 'Brazil Item 2')
        @role = Role.using(:brazil).create!(:name => 'testes')
      end

      it 'update_attributes' do
        @permission_brazil_2.update_attributes(:role_ids => [@role.id])
        expect(@permission_brazil_2.roles.to_set).to eq([@role].to_set)
      end

      it 'update_attribute' do
        @permission_brazil_2.update_attribute(:role_ids, [@role.id])
        expect(@permission_brazil_2.roles.to_set).to eq([@role].to_set)
      end

      it '<<' do
        @permission_brazil_2.roles << @role
        @role.save
        @permission_brazil_2.save
        @permission_brazil_2.reload
        expect(@permission_brazil_2.roles.to_set).to eq([@role].to_set)
      end

      it 'build' do
        role = @permission_brazil_2.roles.build(:name => 'Builded Role')
        @permission_brazil_2.save
        expect(@permission_brazil_2.roles.to_set).to eq([role].to_set)
      end

      it 'create' do
        role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.to_set).to eq([role].to_set)
      end

      it 'create' do
        role = @permission_brazil_2.roles.create!(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.to_set).to eq([role].to_set)
      end

      it 'count' do
        expect(@permission_brazil_2.roles.count).to eq(0)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.count).to eq(1)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.count).to eq(2)
      end

      it 'size' do
        expect(@permission_brazil_2.roles.size).to eq(0)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.size).to eq(1)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.size).to eq(2)
      end

      it 'length' do
        expect(@permission_brazil_2.roles.length).to eq(0)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.length).to eq(1)
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.length).to eq(2)
      end

      it 'empty?' do
        expect(@permission_brazil_2.roles.empty?).to be true
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.empty?).to be false
      end

      it 'delete_all' do
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.empty?).to be false
        @permission_brazil_2.roles.delete_all
        expect(@permission_brazil_2.roles.empty?).to be true
      end

      it 'destroy_all' do
        _role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.empty?).to be false
        @permission_brazil_2.roles.destroy_all
        expect(@permission_brazil_2.roles.empty?).to be true
      end

      it 'find' do
        role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.first).to eq(role)
        @permission_brazil_2.roles.destroy_all
        expect(@permission_brazil_2.roles.first).to be_nil
      end

      it 'exists?' do
        role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.exists?(role)).to be true
        @permission_brazil_2.roles.destroy_all
        expect(@permission_brazil_2.roles.exists?(role)).to be false
      end

      it 'clear' do
        _rol = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.empty?).to be false
        @permission_brazil_2.roles.clear
        expect(@permission_brazil_2.roles.empty?).to be true
      end

      it 'delete' do
        role = @permission_brazil_2.roles.create(:name => 'Builded Role')
        expect(@permission_brazil_2.roles.empty?).to be false
        @permission_brazil_2.roles.delete(role)
        @permission_brazil_2.reload
        @role.reload
        expect(@role.permissions).to eq([])
        expect(@permission_brazil_2.roles).to eq([])
      end
    end
  end

  describe 'when you have has_many :through' do
    before(:each) do
      @programmer = Programmer.using(:brazil).create!(:name => 'Thiago')
      @project = Project.using(:brazil).create!(:name => 'RubySoc')
      @project2 = Project.using(:brazil).create!(:name => 'Cobol Application')
      @programmer.projects << @project
      @programmer.save
      Project.using(:master).create!(:name => 'Project Master')
    end

    it 'should find all models in the specified shard' do
      expect(@programmer.project_ids).to eq([@project.id])
      expect(@programmer.projects).to eq([@project])

      expect(@programmer.projects.first).to eq(@project)
      expect(@programmer.projects.last).to eq(@project)
    end

    it 'should update the attribute for the item' do
      new_brazil_programmer = Programmer.using(:brazil).create!(:name => 'Joao')
      @project.programmers = [new_brazil_programmer]
      expect(@project.programmers).to eq([new_brazil_programmer])
      @project.save
      @project.reload
      expect(@project.programmer_ids).to eq([new_brazil_programmer.id])
      expect(@project.programmers).to eq([new_brazil_programmer])
    end

    it 'should works for create method' do
      new_brazil_programmer = Programmer.using(:brazil).create!(:name => 'Joao')
      c = new_brazil_programmer.projects.create(:name => 'new Project')
      c.save
      new_brazil_programmer.save
      expect(c.programmers).to eq([new_brazil_programmer])
      expect(new_brazil_programmer.projects).to eq([c])
    end

    describe 'it should works when using' do
      before(:each) do
        @new_brazil_programmer = Programmer.using(:brazil).create!(:name => 'Jose')
        @project = Project.using(:brazil).create!(:name => 'VB Application :-(')
      end

      it 'update_attributes' do
        @new_brazil_programmer.update_attributes(:project_ids => [@project.id])
        expect(@new_brazil_programmer.projects.to_set).to eq([@project].to_set)
      end

      it 'update_attribute' do
        @new_brazil_programmer.update_attribute(:project_ids, [@project.id])
        expect(@new_brazil_programmer.projects.to_set).to eq([@project].to_set)
      end

      it '<<' do
        @new_brazil_programmer.projects << @project
        @project.save
        @new_brazil_programmer.save
        @new_brazil_programmer.reload
        expect(@new_brazil_programmer.projects.to_set).to eq([@project].to_set)
      end

      it 'build' do
        role = @new_brazil_programmer.projects.build(:name => 'New VB App :-/')
        @new_brazil_programmer.save
        expect(@new_brazil_programmer.projects.to_set).to eq([role].to_set)
      end

      it 'create' do
        role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.to_set).to eq([role].to_set)
      end

      it 'create' do
        role = @new_brazil_programmer.projects.create!(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.to_set).to eq([role].to_set)
      end

      it 'count' do
        expect(@new_brazil_programmer.projects.count).to eq(0)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.count).to eq(1)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.count).to eq(2)
      end

      it 'size' do
        expect(@new_brazil_programmer.projects.size).to eq(0)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.size).to eq(1)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.size).to eq(2)
      end

      it 'length' do
        expect(@new_brazil_programmer.projects.length).to eq(0)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.length).to eq(1)
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.length).to eq(2)
      end

      it 'empty?' do
        expect(@new_brazil_programmer.projects.empty?).to be true
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.empty?).to be false
      end

      it 'delete_all' do
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.empty?).to be false
        @new_brazil_programmer.projects.delete_all
        expect(@new_brazil_programmer.projects.empty?).to be true
      end

      it 'destroy_all' do
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.empty?).to be false
        @new_brazil_programmer.projects.destroy_all
        expect(@new_brazil_programmer.projects.empty?).to be true
      end

      it 'find' do
        role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.first).to eq(role)
        @new_brazil_programmer.projects.destroy_all
        expect(@new_brazil_programmer.projects.first).to be_nil
      end

      it 'exists?' do
        role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.exists?(role)).to be true
        @new_brazil_programmer.projects.destroy_all
        expect(@new_brazil_programmer.projects.exists?(role)).to be false
      end

      it 'clear' do
        _role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.empty?).to be false
        @new_brazil_programmer.projects.clear
        expect(@new_brazil_programmer.projects.empty?).to be true
      end

      it 'delete' do
        role = @new_brazil_programmer.projects.create(:name => 'New VB App :-/')
        expect(@new_brazil_programmer.projects.empty?).to be false
        @new_brazil_programmer.projects.delete(role)
        @new_brazil_programmer.reload
        @project.reload
        expect(@project.programmers).to eq([])
        expect(@new_brazil_programmer.projects).to eq([])
      end
    end
  end

  describe 'when you have a 1 x N relationship' do
    before(:each) do
      @brazil_client = Client.using(:brazil).create!(:name => 'Brazil Client')
      @master_client = Client.create!(:name => 'Master Client')
      @item_brazil = Item.using(:brazil).create!(:name => 'Brazil Item', :client => @brazil_client)
      @item_master = Item.create!(:name => 'Master Item', :client => @master_client)
      @brazil_client = Client.using(:brazil).find_by_name('Brazil Client')
      Client.using(:master).create!(:name => 'teste')
    end

    it 'should find all models in the specified shard' do
      expect(@brazil_client.item_ids).to eq([@item_brazil.id])
      expect(@brazil_client.items).to eq([@item_brazil])

      expect(@brazil_client.items.last).to eq(@item_brazil)
      expect(@brazil_client.items.first).to eq(@item_brazil)
    end

    it 'should finds the client that the item belongs' do
      expect(@item_brazil.client).to eq(@brazil_client)
    end

    it 'should raise error if you try to add a record from a different shard' do
      expect do
        @brazil_client.items << Item.using(:canada).create!(:name => 'New User')
      end.to raise_error('Association Error: Records are from different shards')
    end

    it 'should update the attribute for the item' do
      new_brazil_client = Client.using(:brazil).create!(:name => 'new Client')
      @item_brazil.client = new_brazil_client
      expect(@item_brazil.client).to eq(new_brazil_client)
      @item_brazil.save
      @item_brazil.reload
      expect(@item_brazil.client_id).to eq(new_brazil_client.id)
      expect(@item_brazil.client).to eq(new_brazil_client)
    end

    it 'should works for build method' do
      item2 = Item.using(:brazil).create!(:name => 'Brazil Item')
      c = item2.create_client(:name => 'new Client')
      c.save
      item2.save
      expect(item2.client).to eq(c)
      expect(c.items).to eq([item2])
    end

    context 'when calling methods on a collection generated by an association' do
      let(:collection) { @brazil_client.items }
      before :each do
        @brazil_client.items.create(:name => 'Brazil Item #2')
      end

      it "can call collection indexes directly without resetting the collection's current_shard" do
        last_item = collection[1]
        expect(collection.length).to eq(2)
        expect(collection).to eq([collection[0], last_item])
      end

      it "can call methods on the collection without resetting the collection's current_shard" do
        last_item = collection[collection.size - 1]
        expect(collection.length).to eq(2)
        expect(collection).to eq([collection[0], last_item])
      end
    end

    describe 'it should works when using' do
      before(:each) do
        @item_brazil_2 = Item.using(:brazil).create!(:name => 'Brazil Item 2')
        expect(@brazil_client.items.to_set).to eq([@item_brazil].to_set)
      end

      it 'update_attributes' do
        @brazil_client.update_attributes(:item_ids => [@item_brazil_2.id, @item_brazil.id])
        expect(@brazil_client.items.to_set).to eq([@item_brazil, @item_brazil_2].to_set)
      end

      it 'update_attribute' do
        @brazil_client.update_attribute(:item_ids, [@item_brazil_2.id, @item_brazil.id])
        expect(@brazil_client.items.to_set).to eq([@item_brazil, @item_brazil_2].to_set)
      end

      it '<<' do
        @brazil_client.items << @item_brazil_2
        expect(@brazil_client.items.to_set).to eq([@item_brazil, @item_brazil_2].to_set)
      end

      it 'all' do
        item = @brazil_client.items.build(:name => 'Builded Item')
        item.save
        i = @brazil_client.items
        expect(i.to_set).to eq([@item_brazil, item].to_set)
        expect(i.reload.all.to_set).to eq([@item_brazil, item].to_set)
      end

      it 'build' do
        item = @brazil_client.items.build(:name => 'Builded Item')
        item.save
        expect(@brazil_client.items.to_set).to eq([@item_brazil, item].to_set)
      end

      it 'create' do
        item = @brazil_client.items.create(:name => 'Builded Item')
        expect(@brazil_client.items.to_set).to eq([@item_brazil, item].to_set)
      end

      it 'count' do
        expect(@brazil_client.items.count).to eq(1)
        _itm = @brazil_client.items.create(:name => 'Builded Item')
        expect(@brazil_client.items.count).to eq(2)
      end

      it 'size' do
        expect(@brazil_client.items.size).to eq(1)
        _itm = @brazil_client.items.create(:name => 'Builded Item')
        expect(@brazil_client.items.size).to eq(2)
      end

      it 'create!' do
        item = @brazil_client.items.create!(:name => 'Builded Item')
        expect(@brazil_client.items.to_set).to eq([@item_brazil, item].to_set)
      end

      it 'length' do
        expect(@brazil_client.items.length).to eq(1)
        _itm = @brazil_client.items.create(:name => 'Builded Item')
        expect(@brazil_client.items.length).to eq(2)
      end

      it 'empty?' do
        expect(@brazil_client.items.empty?).to be false
        c = Client.create!(:name => 'Client1')
        expect(c.items.empty?).to be true
      end

      it 'delete' do
        expect(@brazil_client.items.empty?).to be false
        @brazil_client.items.delete(@item_brazil)
        @brazil_client.reload
        @item_brazil.reload
        expect(@item_brazil.client).to be_nil
        expect(@brazil_client.items).to eq([])
        expect(@brazil_client.items.empty?).to be true
      end

      it 'delete_all' do
        expect(@brazil_client.items.empty?).to be false
        @brazil_client.items.delete_all
        expect(@brazil_client.items.empty?).to be true
      end

      it 'destroy_all' do
        expect(@brazil_client.items.empty?).to be false
        @brazil_client.items.destroy_all
        expect(@brazil_client.items.empty?).to be true
      end

      it 'find' do
        expect(@brazil_client.items.first).to eq(@item_brazil)
        @brazil_client.items.destroy_all
        expect(@brazil_client.items.first).to be_nil
      end

      it 'exists?' do
        expect(@brazil_client.items.exists?(@item_brazil)).to be true
        @brazil_client.items.destroy_all
        expect(@brazil_client.items.exists?(@item_brazil)).to be false
      end

      it 'uniq' do
        expect(@brazil_client.items.uniq).to eq([@item_brazil])
      end

      it 'clear' do
        expect(@brazil_client.items.empty?).to be false
        @brazil_client.items.clear
        expect(@brazil_client.items.empty?).to be true
      end
    end
  end

  describe 'when you have a 1 x N polymorphic relationship' do
    before(:each) do
      @brazil_client = Client.using(:brazil).create!(:name => 'Brazil Client')
      @master_client = Client.create!(:name => 'Master Client')
      @comment_brazil = Comment.using(:brazil).create!(:name => 'Brazil Comment', :commentable => @brazil_client)
      @comment_master = Comment.create!(:name => 'Master Comment', :commentable => @master_client)
      @brazil_client = Client.using(:brazil).find_by_name('Brazil Client')
      Client.using(:master).create!(:name => 'teste')
    end

    it 'should find all models in the specified shard' do
      expect(@brazil_client.comment_ids).to eq([@comment_brazil.id])
      expect(@brazil_client.comments).to eq([@comment_brazil])
    end

    it 'should finds the client that the comment belongs' do
      expect(@comment_brazil.commentable).to eq(@brazil_client)
    end

    it 'should update the attribute for the comment' do
      new_brazil_client = Client.using(:brazil).create!(:name => 'new Client')
      @comment_brazil.commentable = new_brazil_client
      expect(@comment_brazil.commentable).to eq(new_brazil_client)
      @comment_brazil.save
      @comment_brazil.reload
      expect(@comment_brazil.commentable_id).to eq(new_brazil_client.id)
      expect(@comment_brazil.commentable).to eq(new_brazil_client)
    end

    describe 'it should works when using' do
      before(:each) do
        @comment_brazil_2 = Comment.using(:brazil).create!(:name => 'Brazil Comment 2')
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil].to_set)
      end

      it 'update_attributes' do
        @brazil_client.update_attributes(:comment_ids => [@comment_brazil_2.id, @comment_brazil.id])
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, @comment_brazil_2].to_set)
      end

      it 'update_attribute' do
        @brazil_client.update_attribute(:comment_ids, [@comment_brazil_2.id, @comment_brazil.id])
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, @comment_brazil_2].to_set)
      end

      it '<<' do
        @brazil_client.comments << @comment_brazil_2
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, @comment_brazil_2].to_set)
      end

      it 'all' do
        comment = @brazil_client.comments.build(:name => 'Builded Comment')
        comment.save
        c = @brazil_client.comments
        expect(c.to_set).to eq([@comment_brazil, comment].to_set)
        expect(c.reload.all.to_set).to eq([@comment_brazil, comment].to_set)
      end

      it 'build' do
        comment = @brazil_client.comments.build(:name => 'Builded Comment')
        comment.save
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, comment].to_set)
      end

      it 'create' do
        comment = @brazil_client.comments.create(:name => 'Builded Comment')
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, comment].to_set)
      end

      it 'count' do
        expect(@brazil_client.comments.count).to eq(1)
        _cmt = @brazil_client.comments.create(:name => 'Builded Comment')
        expect(@brazil_client.comments.count).to eq(2)
      end

      it 'size' do
        expect(@brazil_client.comments.size).to eq(1)
        _cmt = @brazil_client.comments.create(:name => 'Builded Comment')
        expect(@brazil_client.comments.size).to eq(2)
      end

      it 'create!' do
        comment = @brazil_client.comments.create!(:name => 'Builded Comment')
        expect(@brazil_client.comments.to_set).to eq([@comment_brazil, comment].to_set)
      end

      it 'length' do
        expect(@brazil_client.comments.length).to eq(1)
        _cmt = @brazil_client.comments.create(:name => 'Builded Comment')
        expect(@brazil_client.comments.length).to eq(2)
      end

      it 'empty?' do
        expect(@brazil_client.comments.empty?).to be false
        c = Client.create!(:name => 'Client1')
        expect(c.comments.empty?).to be true
      end

      it 'delete' do
        expect(@brazil_client.comments.empty?).to be false
        @brazil_client.comments.delete(@comment_brazil)
        @brazil_client.reload
        @comment_brazil.reload
        expect(@comment_brazil.commentable).to be_nil
        expect(@brazil_client.comments).to eq([])
        expect(@brazil_client.comments.empty?).to be true
      end

      it 'delete_all' do
        expect(@brazil_client.comments.empty?).to be false
        @brazil_client.comments.delete_all
        expect(@brazil_client.comments.empty?).to be true
      end

      it 'destroy_all' do
        expect(@brazil_client.comments.empty?).to be false
        @brazil_client.comments.destroy_all
        expect(@brazil_client.comments.empty?).to be true
      end

      it 'find' do
        expect(@brazil_client.comments.first).to eq(@comment_brazil)
        @brazil_client.comments.destroy_all
        expect(@brazil_client.comments.first).to be_nil
      end

      it 'exists?' do
        expect(@brazil_client.comments.exists?(@comment_brazil)).to be true
        @brazil_client.comments.destroy_all
        expect(@brazil_client.comments.exists?(@comment_brazil)).to be false
      end

      it 'uniq' do
        expect(@brazil_client.comments.uniq).to eq([@comment_brazil])
      end

      it 'clear' do
        expect(@brazil_client.comments.empty?).to be false
        @brazil_client.comments.clear
        expect(@brazil_client.comments.empty?).to be true
      end
    end
  end

  it 'block' do
    @brazil_role = Role.using(:brazil).create!(:name => 'Brazil Role')
    expect(@brazil_role.permissions.build(:name => 'ok').name).to eq('ok')
    expect(@brazil_role.permissions.create(:name => 'ok').name).to eq('ok')
    expect(@brazil_role.permissions.create!(:name => 'ok').name).to eq('ok')
  end
end
