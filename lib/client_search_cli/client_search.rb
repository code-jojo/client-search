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
          client.first_name&.downcase == query_downcase || 
          client.last_name&.downcase == query_downcase
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