Feature: rake db:migrate
  In order move data along shards
  As a developer
  I want to use the rake db:migrate command

  Scenario: db:migrate should work with octopus
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate"
    Then the output should contain "hello world"