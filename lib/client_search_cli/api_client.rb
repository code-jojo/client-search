# frozen_string_literal: true

require "httparty"

module ClientSearchCli
  # API client for interacting with the client search service
  # Handles fetching clients and searching by various criteria
  class ApiClient
    include HTTParty
    base_uri ENV["SHIFTCARE_API_URL"] || "https://appassets02.shiftcare.com/manual"
    format :json

    # Fetch clients from the API
    def fetch_clients
      response = self.class.get("/clients.json")
      handle_response(response)
    rescue Errno::ECONNREFUSED
      puts "Error: Connection refused"
      nil
    rescue Timeout::Error
      puts "Error: Network timeout"
      nil
    rescue HTTParty::Error
      puts "Error: API returned invalid data"
      nil
    rescue StandardError => e
      puts "Error: #{e.message}"
      nil
    end

    # Search for clients by name
    def search_clients_by_name(name)
      return [] if name.nil? || name.strip.empty?

      search_query = name.downcase.strip
      # Split the search query into parts
      search_parts = search_query.split(/\s+/)

      clients = fetch_clients
      filter_clients_by_name(clients, search_query, search_parts)
    end

    # Find duplicate clients based on email
    def find_duplicate_emails
      clients = fetch_clients.map { |client| Client.new(client) }

      # Group clients by email
      clients_by_email = clients.group_by(&:email)

      # Filter out nil/empty emails and groups with only one client
      clients_by_email.select do |email, clients_with_email|
        email && !email.empty? && clients_with_email.length > 1
      end
    end

    private

    def filter_clients_by_name(clients, search_query, search_parts)
      clients.select do |client|
        client_matches_search?(client, search_query, search_parts)
      end
    end

    def client_matches_search?(client, search_query, search_parts)
      full_name = client["full_name"]&.downcase || ""
      email = client["email"]&.downcase || ""

      exact_match?(full_name, search_query) ||
        name_parts_match?(full_name, search_parts) ||
        email_match?(email, search_query)
    end

    def exact_match?(full_name, search_query)
      full_name == search_query
    end

    def name_parts_match?(full_name, search_parts)
      name_parts = full_name.split(/\s+/)

      name_parts.any? do |name_part|
        search_parts.any? do |search_part|
          name_part == search_part || name_part.start_with?(search_part)
        end
      end
    end

    def email_match?(email, search_query)
      email.include?(search_query)
    end

    def handle_response(response)
      if response.success?
        transform_client_data(response.parsed_response)
      else
        handle_error(response)
        nil
      end
    end

    def handle_error(response)
      case response.code
      when 404
        puts "Error: Resource not found (404)"
      when 401
        puts "Error: Unauthorized access (401)"
      when 403
        puts "Error: Forbidden access (403)"
      when 500
        puts "Error: Server error (500)"
      else
        puts "Error: API Error: #{response.code} - #{response.message}"
      end
    end

    def transform_client_data(clients)
      clients = [clients] unless clients.is_a?(Array)

      clients.map do |client|
        client_data = client.transform_keys(&:to_s)
        client_data
      end
    end
  end
end
