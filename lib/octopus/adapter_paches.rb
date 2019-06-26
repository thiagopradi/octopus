# Monkey patch unsupported database adapters that have not 
# used an internal @config hash
class ActiveRecord::ConnectionAdapters::IBM_DBAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
  attr_accessor :config
end
