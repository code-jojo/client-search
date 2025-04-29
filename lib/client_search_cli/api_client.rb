# frozen_string_literal: true

require "httparty"

module ClientSearchCli
  class ApiClient
    include HTTParty
    base_uri ENV["SHIFTCARE_API_URL"] || "https://appassets02.shiftcare.com/manual"
    format :json

    def fetch_clients
      response = self.class.get("/clients.json")
      handle_response(response)
    end

    def search_clients_by_name(name)
      clients = fetch_clients
      return [] unless clients

      clients.select do |client|
        # Try to match on first_name, last_name if present
        first_name = client['first_name'] || ''
        last_name = client['last_name'] || ''
        full_name = "#{first_name} #{last_name}".downcase.strip
        
        # If no name try email
        email = client['email'] || ''
        
        full_name.include?(name.downcase) || 
          email.downcase.include?(name.downcase)
      end
    end

    private

    def handle_response(response)
      if response.success?
        response.parsed_response
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
      when 500..599
        puts "Error: Server error (#{response.code})"
      else
        puts "Error: Request failed with code #{response.code}"
      end
    end
  end
end 