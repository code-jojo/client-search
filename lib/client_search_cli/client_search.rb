# frozen_string_literal: true

module ClientSearchCli
  # Service class for searching and processing client data
  # Provides functionality for finding clients by name, email, and identifying duplicates
  class ClientSearch
    def initialize(api_client)
      @api_client = api_client
    end

    # Search for clients by name
    def search_by_name(query, _options = {})
      query = query.to_s
      raw_clients = @api_client.search_clients_by_name(query)
      raw_clients.map { |data| Client.new(data) }
    end

    # Find clients with duplicate emails in the dataset
    def find_duplicate_emails
      @api_client.find_duplicate_emails
    end
  end
end
