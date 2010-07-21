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
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate VERSION=20100720172715"
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate VERSION=20100720172730"
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate:redo"
    Then the output should contain "CreateItems: reverting - Shard: master"
    Then the output should contain "CreateItems: reverting - Shard: asia"
    Then the output should contain "CreateItems: reverting - Shard: europe"
    Then the output should contain "CreateItems: reverting - Shard: america"
    Then the output should contain "CreateItems: migrating - Shard: master"
    Then the output should contain "CreateItems: migrating - Shard: asia"
    Then the output should contain "CreateItems: migrating - Shard: europe"
    Then the output should contain "CreateItems: migrating - Shard: america"
    
  Scenario: db:migrate finishing the migration
    When I run "cd ~/Projetos/octopus/sample_app && RAILS_ENV=development rake db:migrate"
    Then the output should contain "CreateSampleUsers: migrating - Shard: america"
    Then the output should contain "CreateSampleUsers: migrating - Shard: master"
    Then the output should contain "CreateSampleUsers: migrating - Shard: asia"
    Then the output should contain "CreateSampleUsers: migrating - Shard: europe"
    Then the output should not contain "An error has occurred, this and all later migrations canceled:"
    Then the version of "dev_env" shard should be "20100720210335"
    Then the version of "america" shard should be "20100720210335"
    Then the version of "europe" shard should be "20100720210335"
    Then the version of "asia" shard should be "20100720210335"
