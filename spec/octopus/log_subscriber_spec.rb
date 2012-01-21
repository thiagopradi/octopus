require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

if Octopus.rails3?
  describe Octopus::LogSubscriber do

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
end