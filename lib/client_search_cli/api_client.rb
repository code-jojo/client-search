# frozen_string_literal: true

require "httparty"

module ClientSearchCli
  # API client for interacting with the client search service
  # Handles fetching clients and searching by various criteria
  class ApiClient
    include HTTParty
    base_uri ENV.fetch("SHIFTCARE_API_URL", "https://appassets02.shiftcare.com/manual")
    format :json

    # Fetch clients from the API
    def fetch_clients
      response = self.class.get("/clients.json")
      handle_response(response)
    rescue Errno::ECONNREFUSED, Timeout::Error, HTTParty::Error => e
      error_message = case e
                      when Errno::ECONNREFUSED then "Connection refused"
                      when Timeout::Error then "Network timeout"
                      when HTTParty::Error then "API returned invalid data"
                      else e.message
                      end
      puts "Error: #{error_message}"
      nil
    rescue StandardError => e
      puts "Error: #{e.message}"
      nil
    end

    # Search for clients by name
    def search_clients_by_name(name)
      return [] if name.nil? || name.strip.empty?

      search_query = name.downcase.strip
      search_parts = search_query.split(/\s+/)

      clients = fetch_clients
      return [] unless clients

      filter_clients_by_name(clients, search_query, search_parts)
    end

    # Find duplicate clients based on email
    def find_duplicate_emails
      clients = fetch_clients&.map { |client| Client.new(client) }
      return {} unless clients

      clients_by_email = group_clients_by_email(clients)
      filter_duplicates(clients_by_email)
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
      message = case response.code
                when 404 then "Resource not found (404)"
                when 401 then "Unauthorized access (401)"
                when 403 then "Forbidden access (403)"
                when 500 then "Server error (500)"
                else "API Error: #{response.code} - #{response.message}"
                end
      puts "Error: #{message}"
    end

    def transform_client_data(clients)
      clients = [clients] unless clients.is_a?(Array)
      clients.map { |client| client.transform_keys(&:to_s) }
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
  end
end
