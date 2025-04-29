# frozen_string_literal: true

RSpec.describe ClientSearchCli::ClientSearch do
  let(:api_client) { instance_double(ClientSearchCli::ApiClient) }
  let(:search_service) { described_class.new(api_client) }
  
  let(:raw_clients) do
    [
      { "id" => 1, "first_name" => "John", "last_name" => "Doe", "email" => "john@example.com" },
      { "id" => 2, "first_name" => "Jane", "last_name" => "Smith", "email" => "jane@example.com" }
    ]
  end
  
  describe "#search_by_name" do
    before do
      allow(api_client).to receive(:search_clients_by_name).with("john").and_return(raw_clients.select { |c| c["first_name"] == "John" })
      allow(api_client).to receive(:search_clients_by_name).with("jane").and_return(raw_clients.select { |c| c["first_name"] == "Jane" })
      allow(api_client).to receive(:search_clients_by_name).with("unknown").and_return([])
    end
    
    it "returns client objects for matching names" do
      result = search_service.search_by_name("john")
      expect(result.size).to eq(1)
      expect(result.first).to be_a(ClientSearchCli::Client)
      expect(result.first.name).to eq("John Doe")
    end
    
    it "returns empty array when no matches are found" do
      result = search_service.search_by_name("unknown")
      expect(result).to be_empty
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