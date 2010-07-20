Then /^the "([^"]*)" shard should have one user named "([^"]*)"$/ do |shard_name, user_name|
  User.using(shard_name.to_sym).where(:name => user_name).count.should == 1
end