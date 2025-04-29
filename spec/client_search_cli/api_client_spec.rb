# frozen_string_literal: true

RSpec.describe ClientSearchCli::ApiClient do
  let(:client) { described_class.new }

  describe "#fetch_clients" do
    it "sends a GET request to the clients endpoint" do
      expect(described_class).to receive(:get).with("/clients.json").and_return(double(success?: true, parsed_response: []))
      client.fetch_clients
    end

    context "when the request is successful" do
      let(:mock_response) { double(success?: true, parsed_response: [{ "id" => 1, "first_name" => "John", "last_name" => "Doe" }]) }

      before do
        allow(described_class).to receive(:get).and_return(mock_response)
      end

      it "returns the parsed response" do
        expect(client.fetch_clients).to eq([{ "id" => 1, "first_name" => "John", "last_name" => "Doe" }])
      end
    end

    context "when the request fails" do
      let(:mock_response) { double(success?: false, code: 404) }

      before do
        allow(described_class).to receive(:get).and_return(mock_response)
        allow(client).to receive(:puts)
      end

      it "handles the error and returns nil" do
        expect(client.fetch_clients).to be_nil
      end
    end
  end

  describe "#search_clients_by_name" do
    let(:clients) do
      [
        { "id" => 1, "first_name" => "John", "last_name" => "Doe" },
        { "id" => 2, "first_name" => "Jane", "last_name" => "Smith" }
      ]
    end

    before do
      allow(client).to receive(:fetch_clients).and_return(clients)
    end

    it "filters clients by name (case insensitive)" do
      expect(client.search_clients_by_name("john")).to eq([{ "id" => 1, "first_name" => "John", "last_name" => "Doe" }])
    end

    it "returns empty array when no matches are found" do
      expect(client.search_clients_by_name("unknown")).to eq([])
    end

    it "returns empty array when client fetch fails" do
      allow(client).to receive(:fetch_clients).and_return(nil)
      expect(client.search_clients_by_name("john")).to eq([])
    end
  end
end 