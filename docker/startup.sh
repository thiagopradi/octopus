#!/bin/bash

set -e

# Wait for our two databases to startup
# (docker-compose v3 removes the health check stuff)
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 10
done

>&2 echo "Postgres is ready"

until mysqladmin -u$MYSQL_USER -h $MYSQL_HOST -p$MYSQL_PASSWORD ping; do
  >&2 echo "MySQL is unavailable - sleeping"
  sleep 10
done

>&2 echo "MySQL is ready"

set -x
bundle exec rake db:prepare
bundle exec rake appraisal:install
bundle exec rake spec
set +x
echo Octopus is ready for you.  Run "docker exec octopus /bin/bash"
/bin/sleep infinity
