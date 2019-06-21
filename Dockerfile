FROM ruby:2.5

RUN apt-get update && apt-get install -y \
  mysql-client \
  postgresql

WORKDIR /usr/src/app

# Pull in a full profile for gem/bundler
SHELL ["/bin/bash", "-l", "-c"]

RUN gem install --no-document bundler -v 1.16.6

# Copy only what's needed for bundler
COPY Gemfile ar-octopus.gemspec /usr/src/app/
COPY lib/octopus/version.rb /usr/src/app/lib/octopus/version.rb

RUN bundle install

# Uncomment if you want to copy the octopus repo
# into the Docker image itself.  docker-compose is
# set up to use a bind mount of your local directory
# from the host
#COPY . /usr/src/app

# This just keeps the container running.  Replace
# this with a rails server if you want
CMD ["/bin/sleep", "infinity"]
