Feature: rake db:migrate
  In order move data along shards
  As a developer
  I want to use the rake db:migrate command

  Scenario: db:migrate should work with octopus
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate"
    Then the output should contain "CreateUsers: migrating - Shard: master"
    Then the output should contain "CreateUsers: migrating - Shard: asia"
    Then the output should contain "CreateUsers: migrating - Shard: europe"
    Then the output should contain "CreateUsers: migrating - Shard: america"

  Scenario: db:migrate:redo should work with octopus
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate"
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate:redo"
    Then the output should contain "CreateItems: reverting - Shard: master"
    Then the output should contain "CreateItems: reverting - Shard: asia"
    Then the output should contain "CreateItems: reverting - Shard: europe"
    Then the output should contain "CreateItems: reverting - Shard: america"
    Then the output should contain "CreateItems: migrating - Shard: master"
    Then the output should contain "CreateItems: migrating - Shard: asia"
    Then the output should contain "CreateItems: migrating - Shard: europe"
    Then the output should contain "CreateItems: migrating - Shard: america"
