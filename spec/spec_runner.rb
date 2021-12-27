# !/usr/bin/env ruby

# Most of the code here is copied from /lib/appraisal/cli.rb in the appraisal gem library
require 'rubygems'
require 'bundler/setup'
require 'appraisal'
require 'appraisal/cli'

begin
  appraisal_name = "rails51" # ENV["APPRAISAL_TAG"] # this is just an example, use the appraisal that you have installed
  cmd = [appraisal_name, 'rspec'] + ARGV
  Appraisal::CLI.start(cmd)
rescue Appraisal::AppraisalsNotFound => e
  puts e.message
  exit 127
end
