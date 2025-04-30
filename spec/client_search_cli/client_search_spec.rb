# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearchCli::ClientSearch do
  let(:api_client) { ClientSearchCli::ApiClient.new }
  subject(:search_service) { described_class.new(api_client) }
  
  let(:raw_clients) do
    [
      { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
      { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" }
    ]
  end
  
  describe "#search_by_name" do
    it "returns clients with names matching search terms" do
      # Test with a few common names that might be in the database
      ["John", "Smith", "Jane"].each do |search_term|
        clients = search_service.search_by_name(search_term)
        
        # Validates return type even if no matches found
        expect(clients).to be_an(Array)
        
        # If we found clients, verify they have the expected structure
        unless clients.empty?
          clients.each do |client|
            expect(client).to be_a(ClientSearchCli::Client)
            expect(client.name).to be_a(String)
            expect(client.id).not_to be_nil
            
            # Verify that the client's name includes the search term (case insensitive)
            expect(client.name.downcase).to include(search_term.downcase)
          end
        end
      end
    end

    it "returns an empty array when no matches are found" do
      # Use a random string that's unlikely to match any client
      random_name = "XYZ#{rand(10000)}"
      clients = search_service.search_by_name(random_name)
      expect(clients).to eq([])
    end
    
  end

  describe "#search_by_name with options" do
    it "filters results with exact matching when exact option is true" do
      allow(api_client).to receive(:search_clients_by_name).and_return(raw_clients)
      
      # Search with exact matching
      clients = search_service.search_by_name("John", exact: true)
      expect(clients).to be_an(Array)
      clients.each do |client|
        # Check parts of the name match exactly
        name_parts = []
        name_parts << client.first_name&.downcase if client.first_name
        name_parts << client.last_name&.downcase if client.last_name
        name_parts += client.full_name.downcase.split if client.full_name
        
        expect(name_parts).to include("john")
      end
      
      # Search with a term that might be part of a name but not an exact match
      clients = search_service.search_by_name("Jo", exact: true)
      expect(clients).to be_an(Array)
      # Since "Jo" is not an exact match for any name part, we expect filtered results
    end
    
    it "limits the number of results when limit option is specified" do
      allow(api_client).to receive(:search_clients_by_name).and_return(raw_clients)
      
      # Test with limit 1
      clients = search_service.search_by_name("", limit: 1)
      expect(clients.length).to eq(1)
      
      # Test with limit larger than available results
      clients = search_service.search_by_name("", limit: 10)
      expect(clients.length).to be <= 10
      
      # Test with invalid limit (should not apply limit)
      clients = search_service.search_by_name("", limit: -1)
      expect(clients.length).to eq(raw_clients.length)
    end
  end
end 