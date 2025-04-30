# frozen_string_literal: true

module ClientSearchCli
  class ClientSearch
    def initialize(api_client)
      @api_client = api_client
    end

    # Search for clients by name
    #
    # @param query [String] The name to search for
    # @param options [Hash] The options
    # @return [Array<Client>] The clients 
    def search_by_name(query, options = {})
      raw_clients = @api_client.search_clients_by_name(query)
      
      # Create client objects
      clients = raw_clients.map { |data| Client.new(data) }
      
      # Apply exact filtering if needed
      if options[:exact]
        query_downcase = query.downcase
        clients = clients.select do |client|
          # Check for exact match in first_name, last_name, or full_name parts
          name_parts = []
          name_parts << client.first_name&.downcase if client.first_name
          name_parts << client.last_name&.downcase if client.last_name
          
          # Also check each word in the full name
          if client.full_name
            name_parts += client.full_name.downcase.split
          end
          
          name_parts.any? { |part| part == query_downcase }
        end
      end
      
      # Apply limit if specified
      if options[:limit] && options[:limit] > 0
        clients = clients.take(options[:limit])
      end
      
      clients
    end
    
  end
end 