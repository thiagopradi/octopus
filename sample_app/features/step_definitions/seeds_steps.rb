Then /^the "([^"]*)" shard should have one user named "([^"]*)"$/ do |shard_name, user_name|
  User.using(shard_name.to_sym).where(:name => user_name).count.should == 1
end

Then /^the version of "([^"]*)" shard should be "([^"]*)"$/ do |shard_name, version|
  ab = ActiveRecord::Base.using(shard_name.to_sym).connection.select_value('select * from schema_migrations order by version desc limit 1;')
  version = '' if version == 'nil'
  ab.to_s.should == version
end

When /^I run inside my Rails project "([^"]*)" with enviroment "([^"]*)"$/ do |command, enviroment|
  run("cd #{Rails.root} && RAILS_ENV=#{enviroment} #{command}")
end
