# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearch::ClientSearch do
  subject(:search_service) { described_class.new(api_client) }

  let(:api_client) { ClientSearch::ApiClient.new }
  let(:raw_clients) do
    [
      { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
      { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" }
    ]
  end

  describe "#search_by_field" do
    context "when searching by various fields" do
      let(:mock_clients) do
        [
          { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com", "phone" => "123-456-7890" },
          { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com", "phone" => "987-654-3210" },
          { "id" => 3, "full_name" => "Alice Jones", "email" => "alice@example.com", "phone" => "555-123-4567" }
        ]
      end

      it "searches by email field" do
        email = "jane@example.com"
        expect(api_client).to receive(:search_clients_by_field).with(email, "email").and_return([mock_clients[1]])

        results = search_service.search_by_field(email, "email")
        expect(results.size).to eq(1)
        expect(results.first.email).to eq(email)
      end

      it "searches by custom field" do
        phone = "555-123-4567"
        expect(api_client).to receive(:search_clients_by_field).with(phone, "phone").and_return([mock_clients[2]])

        results = search_service.search_by_field(phone, "phone")
        expect(results.size).to eq(1)
        expect(results.first.data["phone"]).to eq(phone)
      end

      it "handles fields that don't exist" do
        expect(api_client).to receive(:search_clients_by_field).with("value", "nonexistent_field").and_return([])

        results = search_service.search_by_field("value", "nonexistent_field")
        expect(results).to be_empty
      end

      it "passes options to the API client" do
        options = { case_sensitive: true }
        expect(api_client).to receive(:search_clients_by_field).with("John", "full_name").and_return([mock_clients[0]])

        search_service.search_by_field("John", "full_name", options)
      end
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
        allow(api_client).to receive(:search_clients_by_field).and_return(mock_clients)
      end

      it "handles nil search query" do
        expect { search_service.search_by_field(nil, "full_name") }.not_to raise_error
        allow(api_client).to receive(:search_clients_by_field).with(nil, "full_name").and_return(mock_clients)

        clients = search_service.search_by_field(nil, "full_name")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(mock_clients.size)
      end

      it "handles empty string search query" do
        allow(api_client).to receive(:search_clients_by_field).with("", "full_name").and_return(mock_clients)

        clients = search_service.search_by_field("", "full_name")
        expect(clients).to be_an(Array)
        expect(clients.size).to eq(mock_clients.size)
      end

      it "handles nil field parameter" do
        # Should default to "full_name"
        expect(api_client).to receive(:search_clients_by_field).with("O'Brien",
                                                                     "full_name").and_return([mock_clients[2]])

        search_service.search_by_field("O'Brien", nil)
      end

      it "handles empty field parameter" do
        # Should default to "full_name"
        expect(api_client).to receive(:search_clients_by_field).with("O'Brien",
                                                                     "full_name").and_return([mock_clients[2]])

        search_service.search_by_field("O'Brien", "")
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
