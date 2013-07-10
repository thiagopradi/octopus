if Octopus.rails32?
  namespace :db do 
    def create_database(config)
      begin
        if config['adapter'] =~ /sqlite/
          if File.exist?(config['database'])
            $stderr.puts "#{config['database']} already exists"
          else
            begin
              # Create the SQLite database
              ActiveRecord::Base.establish_connection(config)
              ActiveRecord::Base.connection
            rescue Exception => e
              $stderr.puts e, *(e.backtrace)
              $stderr.puts "Couldn't create database for #{config.inspect}"
            end
          end
          return # Skip the else clause of begin/rescue
        else
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection_without_octopus
        end
      rescue
        case config['adapter']
        when /mysql/
          if config['adapter'] =~ /jdbc/
            #FIXME After Jdbcmysql gives this class
            require 'active_record/railties/jdbcmysql_error'
            error_class = ArJdbcMySQL::Error
          else
            error_class = config['adapter'] =~ /mysql2/ ? Mysql2::Error : Mysql::Error
          end
          access_denied_error = 1045

          create_options = mysql_creation_options(config)

          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => nil))
            ActiveRecord::Base.connection.create_database(config['database'], create_options)
            ActiveRecord::Base.establish_connection(config)
          rescue error_class => sqlerr
            if sqlerr.errno == access_denied_error
              print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
              root_password = $stdin.gets.strip
              grant_statement = "GRANT ALL PRIVILEGES ON #{config['database']}.* " \
                "TO '#{config['username']}'@'localhost' " \
                "IDENTIFIED BY '#{config['password']}' WITH GRANT OPTION;"
              ActiveRecord::Base.establish_connection(config.merge(
                  'database' => nil, 'username' => 'root', 'password' => root_password))
              ActiveRecord::Base.connection.create_database(config['database'], mysql_creation_options(config))
              ActiveRecord::Base.connection.execute grant_statement
              ActiveRecord::Base.establish_connection(config)
            else
              $stderr.puts sqlerr.error
              $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{create_options[:charset]}, collation: #{create_options[:collation]}"
              $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config['encoding']
            end
          end
        when /postgresql/
          @encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'
          begin
            ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
            ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
            ActiveRecord::Base.establish_connection(config)
          rescue Exception => e
            $stderr.puts e, *(e.backtrace)
            $stderr.puts "Couldn't create database for #{config.inspect}"
          end
        end
      else
        # Bug with 1.9.2 Calling return within begin still executes else
        $stderr.puts "#{config['database']} already exists" unless config['adapter'] =~ /sqlite/
      end
    end
  end
end
