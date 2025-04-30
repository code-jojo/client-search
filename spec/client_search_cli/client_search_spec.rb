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
    
    context "with edge case inputs" do
      let(:mock_clients) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" },
          { "id" => 3, "full_name" => "O'Brien Wilson", "email" => "obrien@example.com" },
          { "id" => 4, "full_name" => "张伟 (Zhang Wei)", "email" => "zhang@example.com" },
          { "id" => 5, "full_name" => "", "email" => "no-name@example.com" },
          { "id" => 6, "full_name" => nil, "email" => "nil-name@example.com" }
        ]
      end

      before do
        allow(api_client).to receive(:search_clients_by_name).and_return(mock_clients)
      end

      it "handles nil search query" do
        expect { search_service.search_by_name(nil) }.not_to raise_error
        clients = search_service.search_by_name(nil)
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(mock_clients.size)
      end

      it "handles empty string search query" do
        clients = search_service.search_by_name("")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(mock_clients.size)
      end

      it "handles search terms with apostrophes" do
        allow(api_client).to receive(:search_clients_by_name).with("O'Brien").and_return([mock_clients[2]])
        clients = search_service.search_by_name("O'Brien")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(1)
        expect(clients.first.full_name).to eq("O'Brien Wilson")
      end

      it "handles search terms with non-Latin characters" do
        allow(api_client).to receive(:search_clients_by_name).with("张伟").and_return([mock_clients[3]])
        clients = search_service.search_by_name("张伟")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(1)
        expect(clients.first.full_name).to eq("张伟 (Zhang Wei)")
      end

      it "handles search terms with parentheses" do
        allow(api_client).to receive(:search_clients_by_name).with("(Zhang").and_return([mock_clients[3]])
        clients = search_service.search_by_name("(Zhang")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(1)
        expect(clients.first.full_name).to eq("张伟 (Zhang Wei)")
      end
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

    context "with complex options combinations" do
      let(:extended_clients) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" },
          { "id" => 3, "full_name" => "John Smith", "email" => "john.smith@example.com" },
          { "id" => 4, "full_name" => "Johnny Doe", "email" => "johnny@example.com" },
          { "id" => 5, "full_name" => "John Johnson", "email" => "johnson@example.com" }
        ]
      end

      before do
        allow(api_client).to receive(:search_clients_by_name).with("John").and_return(extended_clients.select { |c| c["full_name"].include?("John") })
      end

      it "applies both exact matching and limit constraints correctly" do
        # Should match "John Doe", "John Smith", "John Johnson" but not "Johnny Doe"
        # Then limit to 2 results
        clients = search_service.search_by_name("John", exact: true, limit: 2)
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(2)
        
        # Verify all returned clients have "John" as an exact name part
        clients.each do |client|
          name_parts = client.full_name.split
          expect(name_parts).to include("John")
        end
      end

      it "handles zero limit without errors" do
        clients = search_service.search_by_name("John", limit: 0)
        expect(clients).to be_an(Array)
        # Since limit <= 0 is invalid, it should return all results
        expect(clients.size).to eq(4)
      end

      it "handles string limit values gracefully" do
        # Should treat non-numeric limit as invalid and return all results
        clients = search_service.search_by_name("John", limit: "abc")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(4)
      end
    end
  end
end 