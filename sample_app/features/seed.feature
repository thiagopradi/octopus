Feature: rake db:seed
  In order to create sample records in the database
  As a developer
  I want to use the rake db:seed command

  Scenario: Detect subset of one-line output
    When I run "ruby -e 'puts \"hello world\"'"
    Then the output should contain "hello world"