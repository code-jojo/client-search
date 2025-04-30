# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearchCli::ApiClient do
  subject(:api_client) { described_class.new }

  describe "#fetch_clients" do
    it "successfully fetches clients from the API" do
      clients = api_client.fetch_clients
      expect(clients).not_to be_nil
      expect(clients).to be_an(Array)
      expect(clients.size).to be > 0
      
      # Check structure of returned client data
      sample_client = clients.first
      expect(sample_client).to include("id", "first_name", "last_name", "email", "phone")
    end
  end

  describe "#search_clients_by_name" do
    it "returns matching clients when searching by name" do
      # First get a client with a name to search for
      clients = api_client.fetch_clients
      named_client = clients.find { |c| (c["first_name"] || "").strip != "" || (c["last_name"] || "").strip != "" }
      
      # Skip if no named clients found
      if named_client
        search_term = named_client["first_name"] || named_client["last_name"]
        search_results = api_client.search_clients_by_name(search_term)
        
        expect(search_results).to be_an(Array)
        # At least one result should be returned (the client we're searching for)
        expect(search_results.size).to be >= 1
      else
        skip "No clients with names found for testing search"
      end
    end
  end
end 