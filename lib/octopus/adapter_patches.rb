# Monkey patch unsupported database adapters that have not 
# used an internal @config hash

if Octopus.ibm_db_support?
  class ActiveRecord::ConnectionAdapters::IBM_DBAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
    attr_accessor :config
  end
end
