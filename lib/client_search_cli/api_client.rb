# frozen_string_literal: true

require "httparty"

module ClientSearchCli
  class ApiClient
    include HTTParty
    base_uri ENV["SHIFTCARE_API_URL"]
    format :json
    
    # Fetch clients from the API
    #
    # @return [Array<Hash>] The clients
    def fetch_clients
      response = self.class.get("/clients.json")
      handle_response(response)
    end
    
    # Search for clients by name
    #
    # @param name [String] The name to search for
    # @return [Array<Hash>] The clients
    def search_clients_by_name(name)
      clients = fetch_clients
      return [] unless clients

      search_query = name.downcase
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
        response.parsed_response
      else
        handle_error(response)
        nil
      end
    end

    # Handle the error from the API
    #
    # @param response [HTTParty::Response] The response
    # @return [void]
    def handle_error(response)
      case response.code
      when 404
        puts "Error: Resource not found (404)"
      when 401
        puts "Error: Unauthorized access (401)"
      when 500..599
        puts "Error: Server error (#{response.code})"
      else
        puts "Error: Request failed with code #{response.code}"
      end
    end
  end
end 