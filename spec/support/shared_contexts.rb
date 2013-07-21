shared_context "with query cache enabled" do
  let!(:counter) { ActiveRecord::QueryCounter.new }

  before(:each) do
    ActiveRecord::Base.connection.enable_query_cache!
    counter.query_count = 0
  end

  after(:each) do 
    ActiveRecord::Base.connection.disable_query_cache!
  end

  around(:each) do |example|
    # TODO - Support Rails 3.0
    if Octopus.rails31? || Octopus.rails32?
      active_support_subscribed(counter.to_proc, 'sql.active_record') do 
        example.run
      end
    end
  end
end
