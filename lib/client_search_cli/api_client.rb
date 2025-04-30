# frozen_string_literal: true

require "httparty"

module ClientSearchCli
  class ApiClient
    include HTTParty
    base_uri ENV["SHIFTCARE_API_URL"] || "https://shiftcare-api.example.com"
    format :json
    
    # Fetch clients from the API
    #
    # @return [Array<Hash>] The clients
    def fetch_clients
      begin
        response = self.class.get("/clients.json")
        handle_response(response)
      rescue Errno::ECONNREFUSED
        puts "Error: Connection refused"
        nil
      rescue Timeout::Error
        puts "Error: Network timeout"
        nil
      rescue HTTParty::Error => e
        puts "Error: API returned invalid data"
        nil
      rescue StandardError => e
        puts "Error: #{e.message}"
        nil
      end
    end
    
    # Search for clients by name
    #
    # @param name [String] The name to search for
    # @return [Array<Hash>] The clients
    def search_clients_by_name(name)
      clients = fetch_clients
      return [] unless clients

      # Handle nil search query
      search_query = name.to_s.downcase
      search_terms = search_query.split
      
      clients.select do |client|
        full_name = client['full_name']&.downcase || ''
        email = client['email']&.downcase || ''
        
        if search_terms.size > 1
          # For multi-word searches, all terms must be in the full name
          search_terms.all? { |term| full_name.include?(term) }
        else
          # For single-word searches, only match complete words
          name_parts = full_name.split
          name_parts.any? { |part| part == search_query } || 
            email.include?(search_query)
        end
      end
    end

    private

    # Handle the response from the API
    #
    # @param response [HTTParty::Response] The response
    # @return [Array<Hash>] The clients 
    def handle_response(response)
      if response.success?
        transform_client_data(response.parsed_response)
      else
        handle_error(response)
        nil
      end
    end

    # Handle errors from the API
    #
    # @param response [HTTParty::Response] The response
    # @return [void]
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

    # Transform client data to ensure it has the expected fields
    #
    # @param clients [Array<Hash>] The clients from the API
    # @return [Array<Hash>] The transformed clients
    def transform_client_data(clients)
      clients = [clients] unless clients.is_a?(Array)
      
      clients.map do |client|
        client_data = client.transform_keys(&:to_s)
        client_data
      end
    end
  end
end 