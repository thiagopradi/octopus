#!/bin/bash
set -e
source /home/db2inst1/sqllib/db2profile
db2start
echo "Creating databases, this may take around 6 - 8 minutes per database..."
for db in octopus6 octopus7 octopus8 octopus9; do
  echo "create databse $db"
  time db2 create database $db
done
