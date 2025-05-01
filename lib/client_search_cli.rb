# frozen_string_literal: true

begin
  require "dotenv/load"
rescue LoadError
  # dotenv gem not available
end

require_relative "client_search_cli/version"
require_relative "client_search_cli/api/response_handling"
require_relative "client_search_cli/api/client_search"
require_relative "client_search_cli/api_client"
require_relative "client_search_cli/client"
require_relative "client_search_cli/client_search"
require_relative "client_search_cli/output/table_formatting"
require_relative "client_search_cli/output/formatting_helpers"
require_relative "client_search_cli/output_helpers"
require_relative "client_search_cli/cli"

module ClientSearchCli
  class Error < StandardError; end
end
