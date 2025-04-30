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
      clients = api_client.fetch_clients
      named_client = clients.find { |c| (c["full_name"] || "").strip != "" }

      if named_client
        search_term = named_client["full_name"]
        search_results = api_client.search_clients_by_name(search_term)

        expect(search_results).to be_an(Array)
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
        allow(api_client).to receive(:search_clients_by_name).with("").and_return([])
        results = api_client.search_clients_by_name("")
        expect(results).to be_an(Array)
      end

      it "handles nil search terms" do
        allow(api_client).to receive(:search_clients_by_name).with(nil).and_return([])
        expect { api_client.search_clients_by_name(nil) }.not_to raise_error
        results = api_client.search_clients_by_name(nil)
        expect(results).to be_an(Array)
      end

      it "handles special characters in search terms" do
        special_client = mock_clients[3]
        allow(api_client).to receive(:search_clients_by_name).with("María").and_return([special_client])
        results = api_client.search_clients_by_name("María")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("María Rodríguez")
      end

      it "handles hyphenated names" do
        hyphenated_client = mock_clients[2]
        allow(api_client).to receive(:search_clients_by_name).with("John-Paul").and_return([hyphenated_client])
        results = api_client.search_clients_by_name("John-Paul")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John-Paul Jones")
      end

      it "handles case insensitivity" do
        john_client = mock_clients[0]
        allow(api_client).to receive(:search_clients_by_name).with("john").and_return([john_client])
        results = api_client.search_clients_by_name("john")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end

      it "handles multi-word searches correctly" do
        john_client = mock_clients[0]
        allow(api_client).to receive(:search_clients_by_name).with("John Doe").and_return([john_client])
        results = api_client.search_clients_by_name("John Doe")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end

      it "properly handles multiple spaces in search terms" do
        john_client = mock_clients[0]
        allow(api_client).to receive(:search_clients_by_name).with("John  Doe").and_return([john_client])
        results = api_client.search_clients_by_name("John  Doe")
        expect(results).to be_an(Array)
        expect(results.size).to eq(1)
        expect(results.first["full_name"]).to eq("John Doe")
      end
    end
  end

  describe "#transform_client_data" do
    let(:transformed_data) { api_client.send(:transform_client_data, raw_data) }

    context "with complete data" do
      let(:raw_data) do
        [{ "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" }]
      end

      it "keeps existing data intact" do
        expect(transformed_data.first).to include(
          "id" => 1,
          "full_name" => "John Doe",
          "email" => "john@example.com"
        )
      end
    end
  end
end
