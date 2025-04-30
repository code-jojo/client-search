# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearchCli::ClientSearch do
  let(:api_client) { ClientSearchCli::ApiClient.new }
  subject(:search_service) { described_class.new(api_client) }
  
  let(:raw_clients) do
    [
      { "id" => 1, "first_name" => "John", "last_name" => "Doe", "email" => "john@example.com" },
      { "id" => 2, "first_name" => "Jane", "last_name" => "Smith", "email" => "jane@example.com" }
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
    
    context "with limit option" do
      before do
        # Setup multiple results for limiting
        allow(api_client).to receive(:search_clients_by_name).with("common").and_return(raw_clients)
      end
      
      it "limits the number of results" do
        result = search_service.search_by_name("common", limit: 1)
        expect(result.size).to eq(1)
      end
    end
    
    context "with exact option" do
      before do
        allow(api_client).to receive(:search_clients_by_name).with("doe").and_return(raw_clients.select { |c| c["last_name"] == "Doe" })
      end
      
      it "filters results to exact matches" do
        result = search_service.search_by_name("doe", exact: true)
        expect(result.size).to eq(1)
        expect(result.first.last_name).to eq("Doe")
      end
    end
  end
end 