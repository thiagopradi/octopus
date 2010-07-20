Feature: rake db:seed
  In order to create sample records in the database
  As a developer
  I want to use the rake db:seed command

  Scenario: Detect subset of one-line output
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:seed"
    Then the output should contain "Could not find table 'users'"