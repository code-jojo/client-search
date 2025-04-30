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
      # Convert nil query to empty string to avoid errors
      query = query.to_s
      raw_clients = @api_client.search_clients_by_name(query)
      raw_clients.map { |data| Client.new(data) }
    end
    
    # Find clients with duplicate emails in the dataset
    #
    # @return [Hash<String, Array<Client>>] Hash of duplicate emails with associated clients
    def find_duplicate_emails
      raw_clients = @api_client.fetch_clients
      return {} unless raw_clients
      
      clients = raw_clients.map { |data| Client.new(data) }
      
      # Group clients by email, filtering out nil/empty emails
      email_groups = clients.reject { |c| c.email.nil? || c.email.empty? }
                            .group_by { |client| client.email.downcase }
      
      # Select only groups with more than one client (duplicates)
      email_groups.select { |_, client_group| client_group.size > 1 }
    end
  end
end 