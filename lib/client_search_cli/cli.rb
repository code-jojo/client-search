# frozen_string_literal: true

require "thor"
require "httparty"
require "csv"
require_relative "output_helpers"

module ClientSearchCli
  # Command Line Interface for client search functionality
  # Provides commands for searching and managing client data
  class CLI < Thor
    include OutputHelpers

    def self.exit_on_failure?
      true
    end

    desc "search NAME", "Search for clients by name"
    option :format, type: :string, desc: "Output format (table, json)", default: "table"
    def search(name)
      search_service = ClientSearch.new(ApiClient.new)

      begin
        clients = search_service.search_by_name(name)
        display_results(clients, options[:format])
      rescue Error => e
        error_message(e)
      end
    end

    desc "duplicates", "Find clients with duplicate email addresses"
    option :format, type: :string, desc: "Output format (table, json)", default: "table"
    def duplicates
      search_service = ClientSearch.new(ApiClient.new)

      begin
        duplicate_groups = search_service.find_duplicate_emails
        display_results(duplicate_groups, options[:format], is_duplicate: true)
      rescue Error => e
        error_message(e)
      end
    end

    desc "version", "Display the version of the client-search-cli"
    def version
      puts "client-search-cli version #{ClientSearchCli::VERSION}"
    end

    private

    def display_results(data, format, is_duplicate: false)
      case format.to_s.downcase
      when "json"
        display_as_json(data, is_duplicate: is_duplicate)
      else
        display_as_table(data, is_duplicate: is_duplicate)
      end
    end

    def error_message(exception)
      say "Error: #{exception.message}", :red
      exit 1
    end
  end
end
