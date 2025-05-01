# frozen_string_literal: true

require "httparty"
require "json"
require_relative "api/response_handling"
require_relative "api/client_search"

module ClientSearchCli
  # API client for interacting with the client search service
  # Handles fetching clients and searching by various criteria
  class ApiClient
    include HTTParty
    include Api::ResponseHandling
    include Api::ClientSearch

    base_uri ENV.fetch("SHIFTCARE_API_URL", "https://appassets02.shiftcare.com/manual")
    format :json

    def initialize(custom_file = nil)
      @custom_file = custom_file
    end

    # Fetch clients from the API or from a custom file
    def fetch_clients
      if @custom_file
        fetch_from_file
      else
        fetch_from_api
      end
    rescue Errno::ECONNREFUSED, Timeout::Error, HTTParty::Error => e
      handle_network_error(e)
    rescue ClientSearchCli::Error
      raise
    rescue StandardError => e
      puts "Error: #{e.message}"
      nil
    end

    # Search for clients by any field
    def search_clients_by_field(value, field = "full_name")
      return [] if value.nil? || value.strip.empty?

      search_query = value.downcase.strip
      search_parts = search_query.split(/\s+/)

      clients = fetch_clients
      return [] unless clients

      filter_clients_by_field(clients, field, search_query, search_parts)
    end

    # Find duplicate clients based on email
    def find_duplicate_emails
      clients = fetch_clients&.map { |client| Client.new(client) }
      return {} unless clients

      find_duplicates(clients)
    end

    private

    def find_duplicates(clients)
      clients_by_email = group_clients_by_email(clients)
      filter_duplicates(clients_by_email)
    end

    def group_clients_by_email(clients)
      clients.each_with_object({}) do |client, result|
        next unless valid_email?(client.email)

        email_key = client.email.downcase
        result[email_key] ||= []
        result[email_key] << client
      end
    end

    def filter_duplicates(grouped_clients)
      grouped_clients.select { |_, clients_group| clients_group.length > 1 }
    end

    def valid_email?(email)
      email && !email.empty?
    end

    def fetch_from_api
      response = self.class.get("/clients.json")
      handle_response(response)
    end

    def fetch_from_file
      raise ClientSearchCli::Error, "File not found: #{@custom_file}" unless File.exist?(@custom_file)

      begin
        data = JSON.parse(File.read(@custom_file))
        transform_client_data(data)
      rescue JSON::ParserError
        raise ClientSearchCli::Error, "Invalid JSON format in file: #{@custom_file}"
      end
    end
  end
end
