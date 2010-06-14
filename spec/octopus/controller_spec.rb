require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Octopus::Controller do
  it "should have the using method to select the shard" do
    a = ActionController::Base.new
    a.respond_to?(:using).should be_true
  end
  
  it "should use #using method to in all requests" do
    class UsersControllers < ActionController::Base
      around_filter :select_shard      
      def create
        User.create!(:name => "ActionController")
        render :nothing => true
      end
      
      def select_shard
        using(:brazil) do
          yield
        end
      end
      
      def self._router
        ActionDispatch::Routing::RouteSet.new
      end      
    end
    
    UsersControllers.action_methods.include?("create").should be_true
    a = UsersControllers.new
    a.stub!(:request).and_return(mock({:fullpath => "", :filtered_parameters => {}, :formats => ["xml"], :method => "GET"}))
    a.instance_variable_set(:@_response, mock(:content_type => "xml", :body= => "", :status => 401))
    a.process(:create)
    
    User.using(:brazil).find_by_name("ActionController").should_not be_nil
    User.using(:master).find_by_name("ActionController").should be_nil
  end
end