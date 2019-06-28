#!/bin/bash
set -e
source /home/db2inst1/sqllib/db2profile
db2start
echo "Creating databases, this may take around 6 - 8 minutes..."
time db2 create database octopus6
