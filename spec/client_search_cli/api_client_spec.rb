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
      expect(sample_client).to include("id", "full_name", "email")
    end

    context "with network errors" do
      before do
        allow(described_class).to receive(:get).and_raise(Errno::ECONNREFUSED)
      end

      it "handles connection errors gracefully" do
        expect { api_client.fetch_clients }.to output(/Error: Connection refused/).to_stdout
        expect(api_client.fetch_clients).to be_nil
      end
    end

    context "with API response errors" do
      let(:error_response) { instance_double("HTTParty::Response", success?: false, code: code) }
      
      [404, 401, 500, 403].each do |status_code|
        context "with #{status_code} status code" do
          let(:code) { status_code }
          
          before do
            allow(described_class).to receive(:get).and_return(error_response)
          end
          
          it "handles #{status_code} error gracefully" do
            expect { api_client.fetch_clients }.to output(/Error/).to_stdout
            expect(api_client.fetch_clients).to be_nil
          end
        end
      end
    end
  end

  describe "#search_clients_by_name" do
    it "returns matching clients when searching by name" do
      # First get a client with a name to search for
      clients = api_client.fetch_clients
      named_client = clients.find { |c| (c["full_name"] || "").strip != "" }
      
      # Skip if no named clients found
      if named_client
        search_term = named_client["full_name"]
        search_results = api_client.search_clients_by_name(search_term)
        
        expect(search_results).to be_an(Array)
        # At least one result should be returned (the client we're searching for)
        expect(search_results.size).to be >= 1
      else
        skip "No clients with names found for testing search"
      end
    end

    context "with edge cases in search terms" do
      let(:mock_clients) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" },
          { "id" => 3, "full_name" => "John-Paul Jones", "email" => "jp@example.com" },
          { "id" => 4, "full_name" => "María Rodríguez", "email" => "maria@example.com" },
          { "id" => 5, "full_name" => "", "email" => "no-name@example.com" },
          { "id" => 6, "full_name" => nil, "email" => "nil-name@example.com" }
        ]
      end

      before do
        allow(api_client).to receive(:fetch_clients).and_return(mock_clients)
      end

      it "handles empty search terms" do
        results = api_client.search_clients_by_name("")
        expect(results).to be_an(Array)
        # Empty search term should return all clients since all names include ""
        expect(results.size).to eq(mock_clients.size)
      end

      it "handles nil search terms" do
        expect { api_client.search_clients_by_name(nil) }.not_to raise_error
        results = api_client.search_clients_by_name(nil)
        expect(results).to be_an(Array)
      end

      it "handles special characters in search terms" do
        results = api_client.search_clients_by_name("María")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("María Rodríguez")
      end

      it "handles hyphenated names" do
        results = api_client.search_clients_by_name("John-Paul")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John-Paul Jones")
      end

      it "handles case insensitivity" do
        results = api_client.search_clients_by_name("john")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end

      it "handles multi-word searches correctly" do
        results = api_client.search_clients_by_name("John Doe")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end

      it "properly handles multiple spaces in search terms" do
        results = api_client.search_clients_by_name("John  Doe")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end
    end
  end

  describe "#transform_client_data" do
    # Access private method for testing
    let(:transformed_data) { api_client.send(:transform_client_data, raw_data) }

    context "with complete data" do
      let(:raw_data) do
        [{ "id" => 1, "full_name" => "John Doe", "first_name" => "John", "last_name" => "Doe", "email" => "john@example.com", "phone" => "123456789" }]
      end

      it "keeps existing data intact" do
        expect(transformed_data.first).to include(
          "id" => 1,
          "full_name" => "John Doe",
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john@example.com",
          "phone" => "123456789"
        )
      end
    end

    context "with incomplete data" do
      let(:raw_data) do
        [{ "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" }]
      end

      it "extracts first and last names from full_name" do
        expect(transformed_data.first).to include(
          "first_name" => "John",
          "last_name" => "Doe"
        )
      end
    end

    context "with missing phone data" do
      let(:raw_data) do
        [{ "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" }]
      end

      it "ensures phone field exists" do
        expect(transformed_data.first).to include("phone" => "")
      end
    end

    context "with multi-word last names" do
      let(:raw_data) do
        [{ "id" => 1, "full_name" => "John van der Waals", "email" => "john@example.com" }]
      end

      it "correctly handles multi-word last names" do
        expect(transformed_data.first).to include(
          "first_name" => "John",
          "last_name" => "van der Waals"
        )
      end
    end
  end
end 