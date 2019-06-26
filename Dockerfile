FROM ruby:2.5

RUN apt-get update && apt-get install -y \
  mysql-client \
  postgresql \
  vim

# Install the IBM DB2 CLI driver.  The ibm_db gem install
# will also do this, but it has no status output and takes 
# several minutes.
ENV IBM_DB_HOME=/opt/ibm/clidriver
RUN wget http://public.dhe.ibm.com/ibmdl/export/pub/software/data/db2/drivers/odbc_cli/linuxx64_odbc_cli.tar.gz -O /tmp/linuxx64_odbc_cli.tar.gz \
  && mkdir -p /opt/ibm \
  && tar -C /opt/ibm -xzvf /tmp/linuxx64_odbc_cli.tar.gz 

WORKDIR /usr/src/app

# Pull in a full profile for gem/bundler
SHELL ["/bin/bash", "-l", "-c"]

RUN gem install --no-document bundler -v 1.16.6

# Copy only what's needed for bundler
COPY Gemfile ar-octopus.gemspec /usr/src/app/
COPY lib/octopus/version.rb /usr/src/app/lib/octopus/version.rb

RUN bundle install --path=.bundle

# Uncomment if you want to copy the octopus repo
# into the Docker image itself.  docker-compose is
# set up to use a bind mount of your local directory
# from the host
#COPY . /usr/src/app

# This just keeps the container running.  Replace
# this with a rails server if you want
CMD ["/bin/sleep", "infinity"]
