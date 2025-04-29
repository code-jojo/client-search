# frozen_string_literal: true

module ClientSearchCli
  class ClientSearch
    def initialize(api_client)
      @api_client = api_client
    end

    def search_by_name(query, options = {})
      raw_clients = @api_client.search_clients_by_name(query)
      
      # Apply exact matching if requested
      if options[:exact]
        raw_clients = filter_exact_match(raw_clients, query)
      end
      
      # Convert to Client objects
      clients = raw_clients.map { |data| Client.new(data) }
      
      # Apply limit if provided
      if options[:limit] && options[:limit] > 0
        clients = clients.first(options[:limit])
      end
      
      clients
    end
    
    private
    
    def filter_exact_match(clients, query)
      query_downcased = query.downcase
      
      clients.select do |client|
        first_name = client["first_name"] || ""
        last_name = client["last_name"] || ""
        email = client["email"] || ""
        
        first_name.downcase == query_downcased || 
          last_name.downcase == query_downcased || 
          "#{first_name} #{last_name}".downcase.strip == query_downcased ||
          email.downcase == query_downcased
      end
    end
  end
end 