Feature: rake db:seed
  In order to create sample records in the database
  As a developer
  I want to use the rake db:seed command

  Scenario: db:seed should fail
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:seed"
    Then the output should contain "Could not find table 'users'"
    
  Scenario: db:seed should work with octopus
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate"
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:seed"
    Then the "asia" shard should have one user named "Asia User"
    Then the "america" shard should have one user named "America User 1"
    Then the "america" shard should have one user named "America User 2"