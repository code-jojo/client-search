# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe ClientSearch::ApiClient do
  subject(:api_client) { described_class.new }

  describe "#initialize" do
    it "initializes without a custom file by default" do
      client = described_class.new
      expect(client.instance_variable_get(:@custom_file)).to be_nil
    end

    it "initializes with a custom file path when specified" do
      client = described_class.new("custom.json")
      expect(client.instance_variable_get(:@custom_file)).to eq("custom.json")
    end
  end

  describe "#fetch_clients" do
    context "with default API source" do
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
        let(:error_response) { instance_double(HTTParty::Response, success?: false, code: code) }

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

    context "with custom JSON file" do
      let(:valid_json) do
        [{
          "id" => 1,
          "name" => "Custom Name",
          "email" => "custom@example.com",
          "phone" => "123-456-7890",
          "custom_field" => "custom value"
        }].to_json
      end

      let(:invalid_json) { "{ This is not valid JSON }" }

      it "loads clients from a custom JSON file" do
        file = Tempfile.new(["clients", ".json"])
        begin
          file.write(valid_json)
          file.close

          client = described_class.new(file.path)
          clients = client.fetch_clients

          expect(clients).not_to be_nil
          expect(clients).to be_an(Array)
          expect(clients.size).to eq(1)
          expect(clients.first).to include(
            "id" => 1,
            "name" => "Custom Name",
            "email" => "custom@example.com",
            "phone" => "123-456-7890",
            "custom_field" => "custom value"
          )
        ensure
          file.unlink
        end
      end

      it "raises an error for non-existent file" do
        client = described_class.new("/nonexistent/path/to/file.json")
        expect { client.fetch_clients }.to raise_error(ClientSearch::Error, /File not found/)
      end

      it "raises an error for invalid JSON" do
        file = Tempfile.new(["invalid", ".json"])
        begin
          file.write(invalid_json)
          file.close

          client = described_class.new(file.path)
          expect { client.fetch_clients }.to raise_error(ClientSearch::Error, /Invalid JSON format/)
        ensure
          file.unlink
        end
      end
    end
  end

  describe "#search_clients_by_field" do
    let(:mock_clients) do
      [
        { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com", "phone" => "123-456-7890" },
        { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com", "phone" => "987-654-3210" },
        { "id" => 3, "full_name" => "John-Paul Jones", "email" => "jp@example.com", "phone" => "555-555-5555" },
        { "id" => 4, "full_name" => "María Rodríguez", "email" => "maria@example.com", "phone" => "111-222-3333" }
      ]
    end

    before do
      allow(api_client).to receive(:fetch_clients).and_return(mock_clients)
    end

    it "searches by name field" do
      results = api_client.search_clients_by_field("John", "name")
      expect(results).to be_an(Array)
      expect(results.size).to eq(2)
      expect(results.map { |c| c["full_name"] }).to include("John Doe", "John-Paul Jones")
    end

    it "searches by email field" do
      results = api_client.search_clients_by_field("jane@example", "email")
      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first["full_name"]).to eq("Jane Smith")
    end

    it "searches by custom field" do
      results = api_client.search_clients_by_field("555-555", "phone")
      expect(results).to be_an(Array)
      expect(results.size).to eq(1)
      expect(results.first["full_name"]).to eq("John-Paul Jones")
    end

    it "handles field variations" do
      # Test for different name field variations
      results = api_client.search_clients_by_field("John", "full_name")
      expect(results.size).to eq(2)

      results = api_client.search_clients_by_field("john@example", "e-mail")
      expect(results.size).to eq(1)
      expect(results.first["email"]).to eq("john@example.com")
    end

    it "returns empty array for non-existent field" do
      results = api_client.search_clients_by_field("value", "nonexistent_field")
      expect(results).to be_empty
    end

    it "returns empty array for no matches" do
      results = api_client.search_clients_by_field("XYZ#{rand(10_000)}", "name")
      expect(results).to be_empty
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

    context "with symbol keys" do
      let(:raw_data) do
        [{ id: 1, full_name: "John Doe", email: "john@example.com" }]
      end

      it "converts symbol keys to strings" do
        expect(transformed_data.first).to include(
          "id" => 1,
          "full_name" => "John Doe",
          "email" => "john@example.com"
        )
      end
    end

    context "with non-array input" do
      let(:raw_data) do
        { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" }
      end

      it "wraps non-array input in an array" do
        expect(transformed_data).to be_an(Array)
        expect(transformed_data.size).to eq(1)
        expect(transformed_data.first).to include(
          "id" => 1,
          "full_name" => "John Doe",
          "email" => "john@example.com"
        )
      end
    end
  end
end
