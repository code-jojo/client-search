# frozen_string_literal: true

module ClientSearch
  # Service class for searching and processing client data
  # Provides functionality for finding clients by name, email, and identifying duplicates
  class ClientSearch
    def initialize(api_client)
      @api_client = api_client
    end

    # Search for clients by any field
    def search_by_field(query, field = nil, _options = {})
      field = "full_name" if field.nil? || field.to_s.strip.empty?

      query = query.to_s
      raw_clients = @api_client.search_clients_by_field(query, field)
      raw_clients.map { |data| Client.new(data) }
    end

    # Find clients with duplicate emails in the dataset
    def find_duplicate_emails
      @api_client.find_duplicate_emails
    end
  end
end
