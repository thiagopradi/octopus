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

until ! /opt/ibm/clidriver/bin/db2cli validate -database $DB2_DATABASE:$DB2_HOST:$DB2_PORT -connect -user $DB2_USERNAME -passwd $DB2_PASSWORD | grep -q FAILED ; do
  >&2 echo "DB2 is unavailable - sleeping"
  sleep 10  
done

>&2 echo "DB2 is ready"

set -x
cd /usr/src/ibm_db/IBM_DB_Adapter/ibm_db/ext
ruby extconf.rb
make
cd /usr/src/app
bundle install
bundle exec rake db:prepare
bundle exec rake appraisal:install
bundle exec rake spec
#Not working yet
#./sample_app/script/ci_build
set +x
echo Octopus is ready for you.  Run \"docker-compose exec octopus /bin/bash\"
/bin/sleep infinity
