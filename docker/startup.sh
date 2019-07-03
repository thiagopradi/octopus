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

echo /opt/ibm/clidriver/bin/db2cli validate -database $DB2_DATABASE:$DB2_HOST:$DB2_PORT -connect -user $DB2_USER -passwd $DB2_PASSWORD

until ! /opt/ibm/clidriver/bin/db2cli validate -database $DB2_DATABASE:$DB2_HOST:$DB2_PORT -connect -user $DB2_USER -passwd $DB2_PASSWORD | grep -q FAILED ; do
  >&2 echo "DB2 is unavailable - sleeping"
  sleep 10  
done

>&2 echo "DB2 is ready"

set -x
cd /usr/src/app
bundle install --path=.bundle
bundle exec appraisal install

# The db migration only works on rails 5.0.  
# See bug https://github.com/ibmdb/ruby-ibmdb/issues/31
bundle exec appraisal rails5 rake db:prepare

# Run the full spec across all rails versions.
# (This takes a while)
bundle exec rake appraisal spec

set +x
echo Octopus is ready for you.  Run \"docker-compose exec octopus /bin/bash\"
/bin/sleep infinity
