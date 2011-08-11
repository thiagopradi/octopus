Feature: rake db:seed
  In order to create sample records in the database
  As a developer
  I want to use the rake db:seed command

  Scenario: db:seed should fail
    When I run inside my Rails project "rake db:seed" with enviroment "development"
    Then the output should contain "pending migrations"

  Scenario: db:seed should work with octopus
    When I run inside my Rails project "rake db:migrate" with enviroment "development"
    When I run inside my Rails project "rake db:seed" with enviroment "development"
    Then the "asia" shard should have one user named "Asia User"
    Then the "america" shard should have one user named "America User 1"
    Then the "america" shard should have one user named "America User 2"