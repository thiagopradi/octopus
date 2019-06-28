FROM ibmcom/db2express-c:latest

SHELL ["/bin/bash", "-l", "-c"]
COPY create_databases.sh /
# Bake the Octopus databases into the DB2 image,
# since they take a very long time to create.
# NOTE: this is the only way to properly source
# the db2 profile environment to use the 
# DB2 CLI command line.
RUN su - db2inst1 -c /create_databases.sh

CMD db2start && sleep infinity
