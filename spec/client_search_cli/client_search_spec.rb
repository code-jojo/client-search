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
      %w[John Smith Jane].each do |search_term|
        clients = search_service.search_by_name(search_term)

        expect(clients).to be_an(Array)

        next if clients.empty?

        clients.each do |client|
          expect(client).to be_a(ClientSearchCli::Client)
          expect(client.name).to be_a(String)
          expect(client.id).not_to be_nil

          expect(client.name.downcase).to include(search_term.downcase)
        end
      end
    end

    it "returns an empty array when no matches are found" do
      random_name = "XYZ#{rand(10_000)}"
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

  describe "#find_duplicate_emails" do
    context "when there are duplicate emails" do
      let(:clients_with_duplicates) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "duplicate@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "unique@example.com" },
          { "id" => 3, "full_name" => "Different Name", "email" => "duplicate@example.com" },
          { "id" => 4, "full_name" => "Another Duplicate", "email" => "another.duplicate@example.com" },
          { "id" => 5, "full_name" => "Yet Another", "email" => "another.duplicate@example.com" }
        ]
      end

      before do
        allow(api_client).to receive(:fetch_clients).and_return(clients_with_duplicates)
      end

      it "returns a hash of duplicate emails grouped with their clients" do
        duplicates = search_service.find_duplicate_emails

        expect(duplicates).to be_a(Hash)
        expect(duplicates.keys).to contain_exactly("duplicate@example.com", "another.duplicate@example.com")
        expect(duplicates["duplicate@example.com"].size).to eq(2)
        expect(duplicates["another.duplicate@example.com"].size).to eq(2)

        duplicate_group = duplicates["duplicate@example.com"]
        expect(duplicate_group.map(&:id)).to contain_exactly(1, 3)
        expect(duplicate_group.map(&:full_name)).to contain_exactly("John Doe", "Different Name")

        duplicate_group = duplicates["another.duplicate@example.com"]
        expect(duplicate_group.map(&:id)).to contain_exactly(4, 5)
        expect(duplicate_group.map(&:full_name)).to contain_exactly("Another Duplicate", "Yet Another")
      end
    end

    context "when there are no duplicate emails" do
      let(:clients_without_duplicates) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" },
          { "id" => 3, "full_name" => "Different Name", "email" => "different@example.com" }
        ]
      end

      before do
        allow(api_client).to receive(:fetch_clients).and_return(clients_without_duplicates)
      end

      it "returns an empty hash" do
        duplicates = search_service.find_duplicate_emails
        expect(duplicates).to be_a(Hash)
        expect(duplicates).to be_empty
      end
    end

    context "with edge cases" do
      it "handles nil or empty emails" do
        clients_with_nil_emails = [
          { "id" => 1, "full_name" => "John Doe", "email" => nil },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "" },
          { "id" => 3, "full_name" => "Different Name", "email" => nil },
          { "id" => 4, "full_name" => "Valid Email", "email" => "valid@example.com" }
        ]

        allow(api_client).to receive(:fetch_clients).and_return(clients_with_nil_emails)

        duplicates = search_service.find_duplicate_emails
        expect(duplicates).to be_a(Hash)
        expect(duplicates).to be_empty
      end

      it "handles nil client data" do
        allow(api_client).to receive(:fetch_clients).and_return(nil)

        duplicates = search_service.find_duplicate_emails
        expect(duplicates).to be_a(Hash)
        expect(duplicates).to be_empty
      end

      it "handles case insensitivity in emails" do
        clients_with_case_differences = [
          { "id" => 1, "full_name" => "John Doe", "email" => "Same@example.com" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "same@example.com" },
          { "id" => 3, "full_name" => "Different Name", "email" => "SAME@EXAMPLE.COM" }
        ]

        allow(api_client).to receive(:fetch_clients).and_return(clients_with_case_differences)

        duplicates = search_service.find_duplicate_emails
        expect(duplicates).to be_a(Hash)
        expect(duplicates.keys).to contain_exactly("same@example.com")
        expect(duplicates["same@example.com"].size).to eq(3)
      end
    end
  end
end
