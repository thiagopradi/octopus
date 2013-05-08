require "spec_helper"

describe Octopus::Logger, :shards => [:canada] do
  before :each do
    @out = StringIO.new
    @log = Octopus::Logger.new(@out)
    ActiveRecord::Base.logger = @log
  end

  after :each do
    ActiveRecord::Base.logger = nil
  end

  it "should add to the default logger what shard the query was sent" do
    User.using(:canada).create!(:name => "test")
    @out.string.should =~ /Shard: canada/
  end

  it "should be deprecated" do
    @last_message = nil
    ActiveSupport::Deprecation.behavior = Proc.new { |message| @last_message = message }
    @log = Octopus::Logger.new(@out)

    if @last_message.is_a?(Array)
      @last_message.first.should =~ /DEPRECATION WARNING: Octopus::Logger is deprecated and will be removed in Octopus 0\.6\.x\./
    else
      @last_message.should =~ /DEPRECATION WARNING: Octopus::Logger is deprecated and will be removed in Octopus 0\.6\.x\./
    end
  end
end
