require "spec_helper"

describe Octopus::AssociationShardTracking, :shards => [:brazil, :master, :canada] do
  describe "when you have a 1 x 1 relationship" do
    before(:each) do
      @computer_brazil = Computer.using(:brazil).create!(:name => "Computer Brazil")
      @computer_master = Computer.create!(:name => "Computer Brazil")
      @keyboard_brazil = Keyboard.using(:brazil).create!(:name => "Keyboard Brazil", :computer => @computer_brazil)
      @keyboard_master = Keyboard.create!(:name => "Keyboard Master", :computer => @computer_master)
    end

    it "should find the models" do
      @keyboard_master.computer.should == @computer_master
      @keyboard_brazil.computer.should == @computer_brazil
    end

    it "should read correctly the relationed model" do
      new_computer_brazil = Computer.using(:brazil).create!(:name => "New Computer Brazil")
      new_computer_master = Computer.create!(:name => "New Computer Brazil")
      @keyboard_brazil.computer = new_computer_brazil
      @keyboard_brazil.save()
      @keyboard_brazil.reload
      @keyboard_brazil.computer_id.should ==  new_computer_brazil.id
      @keyboard_brazil.computer.should ==  new_computer_brazil
      new_computer_brazil.save()
      new_computer_brazil.reload
      new_computer_brazil.keyboard.should == @keyboard_brazil
    end

    it "should work when using #build_computer or #build_keyboard" do
      c = Computer.using(:brazil).create!(:name => "Computer Brazil")
      k = c.build_keyboard(:name => "Building keyboard")
      c.save()
      k.save()
      c.keyboard.should == k
      k.computer_id.should == c.id
      k.computer.should == c
    end

    it "should work when using #create_computer or #create_keyboard" do
      c = Computer.using(:brazil).create!(:name => "Computer Brazil")
      k = c.create_keyboard(:name => "Building keyboard")
      c.save()
      k.save()
      c.keyboard.should == k
      k.computer_id.should == c.id
      k.computer.should == c
    end

    it "should include models" do
      c = Computer.using(:brazil).create!(:name => "Computer Brazil")
      k = c.create_keyboard(:name => "Building keyboard")
      c.save()
      k.save()

      Computer.using(:brazil).includes(:keyboard).find(c.id).should == c
    end
  end

  describe "when you have a N x N relationship" do
    before(:each) do
      @brazil_role = Role.using(:brazil).create!(:name => "Brazil Role")
      @master_role = Role.create!(:name => "Master Role")
      @permission_brazil = Permission.using(:brazil).create!(:name => "Brazil Permission")
      @permission_master = Permission.using(:master).create!(:name => "Master Permission")
      @brazil_role.permissions << @permission_brazil
      @brazil_role.save()
      Client.using(:master).create!(:name => "teste")
    end

    it "should find all models in the specified shard" do
      @brazil_role.permission_ids().should == [@permission_brazil.id]
      @brazil_role.permissions().should == [@permission_brazil]

      @brazil_role.permissions.first.should eq(@permission_brazil)
      @brazil_role.permissions.last.should eq(@permission_brazil)
    end

    it "should finds the client that the item belongs" do
      @permission_brazil.role_ids.should == [@brazil_role.id]
      @permission_brazil.roles.should == [@brazil_role]

      @permission_brazil.roles.first.should eq(@brazil_role)
      @permission_brazil.roles.last.should eq(@brazil_role)
    end

    it "should update the attribute for the item" do
      new_brazil_role = Role.using(:brazil).create!(:name => "new Role")
      @permission_brazil.roles = [new_brazil_role]
      @permission_brazil.roles.should == [new_brazil_role]
      @permission_brazil.save()
      @permission_brazil.reload
      @permission_brazil.role_ids.should == [new_brazil_role.id]
      @permission_brazil.roles().should == [new_brazil_role]
    end

    it "should works for build method" do
      new_brazil_role = Role.using(:brazil).create!(:name => "Brazil Role")
      c = new_brazil_role.permissions.create(:name => "new Permission")
      c.save()
      new_brazil_role.save()
      c.roles().should == [new_brazil_role]
      new_brazil_role.permissions.should == [c]
    end

    describe "it should works when using" do
      before(:each) do
        @permission_brazil_2 = Permission.using(:brazil).create!(:name => "Brazil Item 2")
        @role = Role.using(:brazil).create!(:name => "testes")
      end

      it "update_attributes" do
        @permission_brazil_2.update_attributes(:role_ids => [@role.id])
        @permission_brazil_2.roles.to_set.should == [@role].to_set
      end

      it "update_attribute" do
        @permission_brazil_2.update_attribute(:role_ids, [@role.id])
        @permission_brazil_2.roles.to_set.should == [@role].to_set
      end

      it "<<" do
        @permission_brazil_2.roles << @role
        @role.save()
        @permission_brazil_2.save()
        @permission_brazil_2.reload
        @permission_brazil_2.roles.to_set.should == [@role].to_set
      end

      it "build" do
        role = @permission_brazil_2.roles.build(:name => "Builded Role")
        @permission_brazil_2.save()
        @permission_brazil_2.roles.to_set.should == [role].to_set
      end

      it "create" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.to_set.should == [role].to_set
      end

      it "create" do
        role = @permission_brazil_2.roles.create!(:name => "Builded Role")
        @permission_brazil_2.roles.to_set.should == [role].to_set
      end

      it "count" do
        @permission_brazil_2.roles.count.should == 0
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.count.should == 1
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.count.should == 2
      end

      it "size" do
        @permission_brazil_2.roles.size.should == 0
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.size.should == 1
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.size.should == 2
      end

      it "length" do
        @permission_brazil_2.roles.length.should == 0
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.length.should == 1
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.length.should == 2
      end


      it "empty?" do
        @permission_brazil_2.roles.empty?.should be_true
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.empty?.should be_false
      end

      it "delete_all" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.empty?.should be_false
        @permission_brazil_2.roles.delete_all
        @permission_brazil_2.roles.empty?.should be_true
      end

      it "destroy_all" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.empty?.should be_false
        @permission_brazil_2.roles.destroy_all
        @permission_brazil_2.roles.empty?.should be_true
      end

      it "find" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.first.should == role
        @permission_brazil_2.roles.destroy_all
        @permission_brazil_2.roles.first.should be_nil
      end

      it "exists?" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.exists?(role).should be_true
        @permission_brazil_2.roles.destroy_all
        @permission_brazil_2.roles.exists?(role).should be_false
      end

      it "clear" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.empty?.should be_false
        @permission_brazil_2.roles.clear
        @permission_brazil_2.roles.empty?.should be_true
      end

      it "delete" do
        role = @permission_brazil_2.roles.create(:name => "Builded Role")
        @permission_brazil_2.roles.empty?.should be_false
        @permission_brazil_2.roles.delete(role)
        @permission_brazil_2.reload
        @role.reload
        @role.permissions.should == []
        @permission_brazil_2.roles.should == []
      end
    end
  end

  describe "when you have has_many :through" do
    before(:each) do
      @programmer = Programmer.using(:brazil).create!(:name => "Thiago")
      @project = Project.using(:brazil).create!(:name => "RubySoc")
      @project2 = Project.using(:brazil).create!(:name => "Cobol Application")
      @programmer.projects << @project
      @programmer.save()
      Project.using(:master).create!(:name => "Project Master")
    end

    it "should find all models in the specified shard" do
      @programmer.project_ids().should eq([@project.id])
      @programmer.projects().should eq([@project])

      @programmer.projects.first.should eq(@project)
      @programmer.projects.last.should eq(@project)
    end


    it "should update the attribute for the item" do
      new_brazil_programmer = Programmer.using(:brazil).create!(:name => "Joao")
      @project.programmers = [new_brazil_programmer]
      @project.programmers.should == [new_brazil_programmer]
      @project.save()
      @project.reload
      @project.programmer_ids.should == [new_brazil_programmer.id]
      @project.programmers().should == [new_brazil_programmer]
    end

    it "should works for create method" do
      new_brazil_programmer = Programmer.using(:brazil).create!(:name => "Joao")
      c = new_brazil_programmer.projects.create(:name => "new Project")
      c.save()
      new_brazil_programmer.save()
      c.programmers().should == [new_brazil_programmer]
      new_brazil_programmer.projects.should == [c]
    end

    describe "it should works when using" do
      before(:each) do
        @new_brazil_programmer = Programmer.using(:brazil).create!(:name => "Jose")
        @project = Project.using(:brazil).create!(:name => "VB Application :-(")
      end

      it "update_attributes" do
        @new_brazil_programmer.update_attributes(:project_ids => [@project.id])
        @new_brazil_programmer.projects.to_set.should == [@project].to_set
      end

      it "update_attribute" do
        @new_brazil_programmer.update_attribute(:project_ids, [@project.id])
        @new_brazil_programmer.projects.to_set.should == [@project].to_set
      end

      it "<<" do
        @new_brazil_programmer.projects << @project
        @project.save()
        @new_brazil_programmer.save()
        @new_brazil_programmer.reload
        @new_brazil_programmer.projects.to_set.should == [@project].to_set
      end

      it "build" do
        role = @new_brazil_programmer.projects.build(:name => "New VB App :-/")
        @new_brazil_programmer.save()
        @new_brazil_programmer.projects.to_set.should == [role].to_set
      end

      it "create" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.to_set.should == [role].to_set
      end

      it "create" do
        role = @new_brazil_programmer.projects.create!(:name => "New VB App :-/")
        @new_brazil_programmer.projects.to_set.should == [role].to_set
      end

      it "count" do
        @new_brazil_programmer.projects.count.should == 0
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.count.should == 1
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.count.should == 2
      end

      it "size" do
        @new_brazil_programmer.projects.size.should == 0
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.size.should == 1
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.size.should == 2
      end

      it "length" do
        @new_brazil_programmer.projects.length.should == 0
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.length.should == 1
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.length.should == 2
      end


      it "empty?" do
        @new_brazil_programmer.projects.empty?.should be_true
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.empty?.should be_false
      end

      it "delete_all" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.empty?.should be_false
        @new_brazil_programmer.projects.delete_all
        @new_brazil_programmer.projects.empty?.should be_true
      end

      it "destroy_all" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.empty?.should be_false
        @new_brazil_programmer.projects.destroy_all
        @new_brazil_programmer.projects.empty?.should be_true
      end

      it "find" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.first.should == role
        @new_brazil_programmer.projects.destroy_all
        @new_brazil_programmer.projects.first.should be_nil
      end

      it "exists?" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.exists?(role).should be_true
        @new_brazil_programmer.projects.destroy_all
        @new_brazil_programmer.projects.exists?(role).should be_false
      end

      it "clear" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.empty?.should be_false
        @new_brazil_programmer.projects.clear
        @new_brazil_programmer.projects.empty?.should be_true
      end

      it "delete" do
        role = @new_brazil_programmer.projects.create(:name => "New VB App :-/")
        @new_brazil_programmer.projects.empty?.should be_false
        @new_brazil_programmer.projects.delete(role)
        @new_brazil_programmer.reload
        @project.reload
        @project.programmers.should == []
        @new_brazil_programmer.projects.should == []
      end
    end
  end

  describe "when you have a 1 x N relationship" do
    before(:each) do
      @brazil_client = Client.using(:brazil).create!(:name => "Brazil Client")
      @master_client = Client.create!(:name => "Master Client")
      @item_brazil = Item.using(:brazil).create!(:name => "Brazil Item", :client => @brazil_client)
      @item_master = Item.create!(:name => "Master Item", :client => @master_client)
      @brazil_client = Client.using(:brazil).find_by_name("Brazil Client")
      Client.using(:master).create!(:name => "teste")
    end

    it "should find all models in the specified shard" do
      @brazil_client.item_ids.should eq([@item_brazil.id]) 
      @brazil_client.items().should eq([@item_brazil])

      @brazil_client.items.last.should eq(@item_brazil)
      @brazil_client.items.first.should eq(@item_brazil)
    end

    it "should finds the client that the item belongs" do
      @item_brazil.client.should == @brazil_client
    end

    it "should raise error if you try to add a record from a different shard" do
      lambda do
        @brazil_client.items << Item.using(:canada).create!(:name => "New User")
      end.should raise_error("Association Error: Records are from different shards")
    end

    it "should update the attribute for the item" do
      new_brazil_client = Client.using(:brazil).create!(:name => "new Client")
      @item_brazil.client = new_brazil_client
      @item_brazil.client.should == new_brazil_client
      @item_brazil.save()
      @item_brazil.reload
      @item_brazil.client_id.should == new_brazil_client.id
      @item_brazil.client().should == new_brazil_client
    end

    it "should works for build method" do
      item2 = Item.using(:brazil).create!(:name => "Brazil Item")
      c = item2.create_client(:name => "new Client")
      c.save()
      item2.save()
      item2.client.should == c
      c.items().should == [item2]
    end

    context "when calling methods on a collection generated by an association" do
      let(:collection) { @brazil_client.items }
      before :each do
        @brazil_client.items.create(:name => 'Brazil Item #2')
      end

      it "can call collection indexes directly without resetting the collection's current_shard" do
        last_item = collection[1]
        collection.length.should == 2
        collection.should eq([ collection[0], last_item ])
      end

      it "can call methods on the collection without resetting the collection's current_shard" do
        last_item = collection[collection.size-1]
        collection.length.should == 2
        collection.should eq([ collection[0], last_item ])
      end
    end

    describe "it should works when using" do
      before(:each) do
        @item_brazil_2 = Item.using(:brazil).create!(:name => "Brazil Item 2")
        @brazil_client.items.to_set.should == [@item_brazil].to_set
      end


      it "update_attributes" do
        @brazil_client.update_attributes(:item_ids => [@item_brazil_2.id, @item_brazil.id])
        @brazil_client.items.to_set.should == [@item_brazil, @item_brazil_2].to_set
      end

      it "update_attribute" do
        @brazil_client.update_attribute(:item_ids, [@item_brazil_2.id, @item_brazil.id])
        @brazil_client.items.to_set.should == [@item_brazil, @item_brazil_2].to_set
      end

      it "<<" do
        @brazil_client.items << @item_brazil_2
        @brazil_client.items.to_set.should == [@item_brazil, @item_brazil_2].to_set
      end

      it "all" do
        item = @brazil_client.items.build(:name => "Builded Item")
        item.save()
        i = @brazil_client.items
        i.to_set.should == [@item_brazil, item].to_set
        i.reload.all.to_set.should == [@item_brazil, item].to_set
      end

      it "build" do
        item = @brazil_client.items.build(:name => "Builded Item")
        item.save()
        @brazil_client.items.to_set.should == [@item_brazil, item].to_set
      end

      it "create" do
        item = @brazil_client.items.create(:name => "Builded Item")
        @brazil_client.items.to_set.should == [@item_brazil, item].to_set
      end

      it "count" do
        @brazil_client.items.count.should == 1
        item = @brazil_client.items.create(:name => "Builded Item")
        @brazil_client.items.count.should == 2
      end

      it "size" do
        @brazil_client.items.size.should == 1
        item = @brazil_client.items.create(:name => "Builded Item")
        @brazil_client.items.size.should == 2
      end

      it "create!" do
        item = @brazil_client.items.create!(:name => "Builded Item")
        @brazil_client.items.to_set.should == [@item_brazil, item].to_set
      end

      it "length" do
        @brazil_client.items.length.should == 1
        item = @brazil_client.items.create(:name => "Builded Item")
        @brazil_client.items.length.should == 2
      end

      it "empty?" do
        @brazil_client.items.empty?.should be_false
        c = Client.create!(:name => "Client1")
        c.items.empty?.should be_true
      end

      it "delete" do
        @brazil_client.items.empty?.should be_false
        @brazil_client.items.delete(@item_brazil)
        @brazil_client.reload
        @item_brazil.reload
        @item_brazil.client.should be_nil
        @brazil_client.items.should == []
        @brazil_client.items.empty?.should be_true
      end

      it "delete_all" do
        @brazil_client.items.empty?.should be_false
        @brazil_client.items.delete_all
        @brazil_client.items.empty?.should be_true
      end

      it "destroy_all" do
        @brazil_client.items.empty?.should be_false
        @brazil_client.items.destroy_all
        @brazil_client.items.empty?.should be_true
      end

      it "find" do
        @brazil_client.items.first.should == @item_brazil
        @brazil_client.items.destroy_all
        @brazil_client.items.first.should be_nil
      end

      it "exists?" do
        @brazil_client.items.exists?(@item_brazil).should be_true
        @brazil_client.items.destroy_all
        @brazil_client.items.exists?(@item_brazil).should be_false
      end

      it "uniq" do
        @brazil_client.items.uniq.should == [@item_brazil]
      end

      it "clear" do
        @brazil_client.items.empty?.should be_false
        @brazil_client.items.clear
        @brazil_client.items.empty?.should be_true
      end
    end
  end

  describe "when you have a 1 x N polymorphic relationship" do
    before(:each) do
      @brazil_client = Client.using(:brazil).create!(:name => "Brazil Client")
      @master_client = Client.create!(:name => "Master Client")
      @comment_brazil = Comment.using(:brazil).create!(:name => "Brazil Comment", :commentable => @brazil_client)
      @comment_master = Comment.create!(:name => "Master Comment", :commentable => @master_client)
      @brazil_client = Client.using(:brazil).find_by_name("Brazil Client")
      Client.using(:master).create!(:name => "teste")
    end

    it "should find all models in the specified shard" do
      @brazil_client.comment_ids.should == [@comment_brazil.id]
      @brazil_client.comments().should == [@comment_brazil]
    end

    it "should finds the client that the comment belongs" do
      @comment_brazil.commentable.should == @brazil_client
    end

    it "should update the attribute for the comment" do
      new_brazil_client = Client.using(:brazil).create!(:name => "new Client")
      @comment_brazil.commentable = new_brazil_client
      @comment_brazil.commentable.should == new_brazil_client
      @comment_brazil.save()
      @comment_brazil.reload
      @comment_brazil.commentable_id.should == new_brazil_client.id
      @comment_brazil.commentable().should == new_brazil_client
    end

    describe "it should works when using" do
      before(:each) do
        @comment_brazil_2 = Comment.using(:brazil).create!(:name => "Brazil Comment 2")
        @brazil_client.comments.to_set.should == [@comment_brazil].to_set
      end

      it "update_attributes" do
        @brazil_client.update_attributes(:comment_ids => [@comment_brazil_2.id, @comment_brazil.id])
        @brazil_client.comments.to_set.should == [@comment_brazil, @comment_brazil_2].to_set
      end

      it "update_attribute" do
        @brazil_client.update_attribute(:comment_ids, [@comment_brazil_2.id, @comment_brazil.id])
        @brazil_client.comments.to_set.should == [@comment_brazil, @comment_brazil_2].to_set
      end

      it "<<" do
        @brazil_client.comments << @comment_brazil_2
        @brazil_client.comments.to_set.should == [@comment_brazil, @comment_brazil_2].to_set
      end

      it "all" do
        comment = @brazil_client.comments.build(:name => "Builded Comment")
        comment.save()
        c = @brazil_client.comments
        c.to_set.should == [@comment_brazil, comment].to_set
        c.reload.all.to_set.should == [@comment_brazil, comment].to_set
      end

      it "build" do
        comment = @brazil_client.comments.build(:name => "Builded Comment")
        comment.save()
        @brazil_client.comments.to_set.should == [@comment_brazil, comment].to_set
      end

      it "create" do
        comment = @brazil_client.comments.create(:name => "Builded Comment")
        @brazil_client.comments.to_set.should == [@comment_brazil, comment].to_set
      end

      it "count" do
        @brazil_client.comments.count.should == 1
        comment = @brazil_client.comments.create(:name => "Builded Comment")
        @brazil_client.comments.count.should == 2
      end

      it "size" do
        @brazil_client.comments.size.should == 1
        comment = @brazil_client.comments.create(:name => "Builded Comment")
        @brazil_client.comments.size.should == 2
      end

      it "create!" do
        comment = @brazil_client.comments.create!(:name => "Builded Comment")
        @brazil_client.comments.to_set.should == [@comment_brazil, comment].to_set
      end

      it "length" do
        @brazil_client.comments.length.should == 1
        comment = @brazil_client.comments.create(:name => "Builded Comment")
        @brazil_client.comments.length.should == 2
      end

      it "empty?" do
        @brazil_client.comments.empty?.should be_false
        c = Client.create!(:name => "Client1")
        c.comments.empty?.should be_true
      end

      it "delete" do
        @brazil_client.comments.empty?.should be_false
        @brazil_client.comments.delete(@comment_brazil)
        @brazil_client.reload
        @comment_brazil.reload
        @comment_brazil.commentable.should be_nil
        @brazil_client.comments.should == []
        @brazil_client.comments.empty?.should be_true
      end

      it "delete_all" do
        @brazil_client.comments.empty?.should be_false
        @brazil_client.comments.delete_all
        @brazil_client.comments.empty?.should be_true
      end

      it "destroy_all" do
        @brazil_client.comments.empty?.should be_false
        @brazil_client.comments.destroy_all
        @brazil_client.comments.empty?.should be_true
      end

      it "find" do
        @brazil_client.comments.first.should == @comment_brazil
        @brazil_client.comments.destroy_all
        @brazil_client.comments.first.should be_nil
      end

      it "exists?" do
        @brazil_client.comments.exists?(@comment_brazil).should be_true
        @brazil_client.comments.destroy_all
        @brazil_client.comments.exists?(@comment_brazil).should be_false
      end

      it "uniq" do
        @brazil_client.comments.uniq.should == [@comment_brazil]
      end

      it "clear" do
        @brazil_client.comments.empty?.should be_false
        @brazil_client.comments.clear
        @brazil_client.comments.empty?.should be_true
      end
    end
  end

  it "block" do
    @brazil_role = Role.using(:brazil).create!(:name => "Brazil Role")
    @brazil_role.permissions.build(:name => "ok").name.should == "ok"
    @brazil_role.permissions.create(:name => "ok").name.should == "ok"
    @brazil_role.permissions.create!(:name => "ok").name.should == "ok"
  end
end
