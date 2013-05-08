require "spec_helper"

describe Octopus::LogSubscriber, :shards => [:canada] do
  before :each do
    @out = StringIO.new
    @log = Logger.new(@out)
    ActiveRecord::Base.logger = @log
    ActiveRecord::Base.logger.level = Logger::DEBUG
  end

  after :each do
    ActiveRecord::Base.logger = nil
  end

  it "should add to the default logger the shard name the query was sent to" do
    User.using(:canada).create!(:name => "test")
    @out.string.should =~ /Shard: canada/
  end
end
