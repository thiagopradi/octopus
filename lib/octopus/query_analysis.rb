module Octopus
  module QueryAnalysis
    # Given a mysql query string, determines if it is definitely a select query. Due to the simple regex used, it will
    # sometimes miss detecting valid select queries, hence why it only determines if something is definitely a select.
    def definitely_select_query?( str )
      str =~ /^\s*select/i
    end

    # Given a mysql query string, determines if the string might contain multiple queries.
    # We are simply checking if it contains a semi colon with non whitespace to the right of it, so this check will
    # sometimes falsely detect a string containing one query as sometimes having multiple queries.
    def possibly_multiple_queries?( str )
      str =~ /;.*\S+.*$/
    end
  end
end