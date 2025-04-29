# frozen_string_literal: true

require "dotenv/load"
require_relative "client_search_cli/version"
require_relative "client_search_cli/api_client"
require_relative "client_search_cli/client"
require_relative "client_search_cli/client_search"
require_relative "client_search_cli/cli"

module ClientSearchCli
  class Error < StandardError; end
  # Your code goes here...
end 