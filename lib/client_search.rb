# frozen_string_literal: true

begin
  require "dotenv/load"
rescue LoadError
  # dotenv gem not available
end

require_relative "client_search/version"
require_relative "client_search/api/response_handling"
require_relative "client_search/api/client_search"
require_relative "client_search/api_client"
require_relative "client_search/client"
require_relative "client_search/client_search"
require_relative "client_search/output/table_formatting"
require_relative "client_search/output/formatting_helpers"
require_relative "client_search/output_helpers"
require_relative "client_search/cli"
# Optional require for the API server - only loaded when needed
# to avoid Sinatra dependency for CLI users
begin
  require_relative "client_search/api_server"
rescue LoadError
  # Sinatra not available - API server won't be loaded
end

module ClientSearch
  Error = Class.new(StandardError)
end
