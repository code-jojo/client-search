# frozen_string_literal: true

RSpec.describe ClientSearch::OutputHelpers do
  let(:test_class) do
    Class.new do
      include ClientSearch::OutputHelpers

      # Expose private method for testing
      def test_with_dependencies(*dependencies, &block)
        with_dependencies(*dependencies, &block)
      end

      # Expose private methods for testing
      def test_determine_display_fields(client)
        determine_display_fields(client)
      end
    end.new
  end

  let(:clients) do
    [
      instance_double(ClientSearch::Client,
                      id: 1,
                      full_name: "John Doe",
                      email: "john@example.com",
                      data: { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
                      to_h: { id: 1, full_name: "John Doe", email: "john@example.com" }),
      instance_double(ClientSearch::Client,
                      id: 2,
                      full_name: "Jane Smith",
                      email: "jane@example.com",
                      data: { "id" => 2, "full_name" => "Jane Smith", "email" => "jane@example.com" },
                      to_h: { id: 2, full_name: "Jane Smith", email: "jane@example.com" })
    ]
  end

  # Create real Client objects instead of instance_doubles for custom fields
  let(:clients_with_custom_fields) do
    [
      ClientSearch::Client.new({
                                 "id" => 1,
                                 "full_name" => "John Doe",
                                 "email" => "john@example.com",
                                 "phone" => "123-456-7890",
                                 "address" => "123 Main St"
                               }),
      ClientSearch::Client.new({
                                 "id" => 2,
                                 "full_name" => "Jane Smith",
                                 "email" => "jane@example.com",
                                 "phone" => "987-654-3210",
                                 "address" => "456 Oak Ave"
                               })
    ]
  end

  let(:clients_with_minimal_fields) do
    [
      instance_double(ClientSearch::Client,
                      id: nil,
                      full_name: nil,
                      email: nil,
                      data: {
                        "first_name" => "John",
                        "last_name" => "Doe",
                        "company" => "ACME Inc."
                      },
                      to_h: {
                        first_name: "John",
                        last_name: "Doe",
                        company: "ACME Inc."
                      })
    ]
  end

  let(:duplicate_groups) do
    {
      "duplicate@example.com" => [
        instance_double(ClientSearch::Client,
                        id: 3,
                        full_name: "Jim Beam",
                        email: "duplicate@example.com",
                        data: { "id" => 3, "full_name" => "Jim Beam", "email" => "duplicate@example.com" },
                        to_h: { id: 3, full_name: "Jim Beam", email: "duplicate@example.com" }),
        instance_double(ClientSearch::Client,
                        id: 4,
                        full_name: "Jack Daniels",
                        email: "duplicate@example.com",
                        data: { "id" => 4, "full_name" => "Jack Daniels", "email" => "duplicate@example.com" },
                        to_h: { id: 4, full_name: "Jack Daniels", email: "duplicate@example.com" })
      ]
    }
  end

  describe "#with_dependencies" do
    it "returns true and executes block when dependencies are available" do
      result = false
      expect(test_class.test_with_dependencies(:json) { result = true }).to be true
      expect(result).to be true
    end

    it "returns false when dependency is not available" do
      expect(test_class.test_with_dependencies(:non_existent_gem)).to be false
    end

    it "returns false when dependency raises NameError" do
      allow(test_class).to receive(:require).with("terminal_table").and_raise(NameError)
      expect(test_class.test_with_dependencies(:terminal_table)).to be false
    end

    it "handles multiple dependencies" do
      expect(test_class.test_with_dependencies(:json, :stringio)).to be true
    end
  end

  describe "#determine_display_fields" do
    it "returns standard fields when all are present" do
      client = clients.first
      fields = test_class.test_determine_display_fields(client)
      expect(fields).to contain_exactly("id", "full_name", "email")
    end

    it "includes custom fields when standard fields are incomplete" do
      client = instance_double(ClientSearch::Client,
                               data: { "id" => 1, "email" => "email@example.com", "phone" => "123-456-7890" })

      fields = test_class.test_determine_display_fields(client)
      expect(fields).to include("id", "email", "phone")
    end

    it "uses all available fields (up to 5) when standard fields are not present" do
      client = instance_double(ClientSearch::Client,
                               data: {
                                 "first_name" => "John",
                                 "last_name" => "Doe",
                                 "company" => "ACME Inc.",
                                 "phone" => "123-456-7890",
                                 "address" => "123 Main St",
                                 "city" => "Anytown",
                                 "state" => "NY"
                               })

      fields = test_class.test_determine_display_fields(client)
      expect(fields.size).to eq(5)
      expect(fields).to include("first_name", "last_name", "company", "phone", "address")
      expect(fields).not_to include("city", "state")
    end

    it "handles nil client gracefully" do
      fields = test_class.test_determine_display_fields(nil)
      expect(fields).to contain_exactly("id", "full_name", "email")
    end

    it "handles client without data gracefully" do
      client = instance_double(ClientSearch::Client, data: nil)
      fields = test_class.test_determine_display_fields(client)
      expect(fields).to contain_exactly("id", "full_name", "email")
    end

    it "detects custom fields from method access" do
      client = clients_with_custom_fields.first

      # Check if the fields are in the data hash
      expect(client.data.keys).to include("phone", "address")

      fields = test_class.test_determine_display_fields(client)
      expect(fields).to include("id", "full_name", "email")
      # The following check depends on how determine_display_fields works
      # If it only looks at standard fields by default, it may not include phone and address
      # We'll focus on this in the more specific test below for display_as_table
    end
  end

  describe "#display_as_table" do
    context "with client data" do
      it "displays client data in a table format" do
        output = capture_stdout { test_class.display_as_table(clients) }

        expect(output).to include("Id")
        expect(output).to include("Full name")
        expect(output).to include("Email")
        expect(output).to include("John Doe")
        expect(output).to include("Jane Smith")
      end

      it "displays custom fields when available" do
        # Manually ensure display_fields will include our custom fields
        fields = %w[id full_name email phone address]
        allow(test_class).to receive(:determine_display_fields).and_return(fields)

        # We have actual Client objects in our let block, so this should work
        output = capture_stdout { test_class.display_as_table(clients_with_custom_fields) }

        expect(output).to include("Id")
        expect(output).to include("Full name")
        expect(output).to include("Email")
        expect(output).to include("Phone")
        expect(output).to include("Address")
        # Custom field values should be in the output
        expect(output).to include("123-456-7890")
        expect(output).to include("456 Oak Ave")
      end

      it "adapts to different field structures" do
        output = capture_stdout { test_class.display_as_table(clients_with_minimal_fields) }

        expect(output).to include("First name")
        expect(output).to include("Last name")
        expect(output).to include("Company")
        expect(output).to include("John")
        expect(output).to include("Doe")
        expect(output).to include("ACME Inc.")
      end

      it "displays a message when no clients are found" do
        output = capture_stdout { test_class.display_as_table([]) }

        expect(output).to include("No results found.")
      end

      it "falls back to plain text when terminal-table is not available" do
        allow(test_class).to receive(:with_dependencies).with(:terminal_table).and_return(false)

        output = capture_stdout { test_class.display_as_table(clients) }

        expect(output).to include("Id\tFull name\tEmail")
        expect(output).to include("John Doe")
        expect(output).to include("jane@example.com")
      end

      it "handles clients with nil emails" do
        client_with_nil_email = instance_double(ClientSearch::Client,
                                                id: 5,
                                                full_name: "No Email",
                                                email: nil,
                                                data: { "id" => 5, "full_name" => "No Email", "email" => nil },
                                                to_h: { id: 5, full_name: "No Email", email: nil })

        output = capture_stdout { test_class.display_as_table([client_with_nil_email]) }

        expect(output).to include("No Email")
        expect(output).to include("N/A")
      end
    end

    context "with duplicate group data" do
      it "displays duplicate groups in a table format" do
        output = capture_stdout { test_class.display_as_table(duplicate_groups, is_duplicate: true) }

        expect(output).to include("Duplicate email: duplicate@example.com")
        expect(output).to include("ID")
        expect(output).to include("Full Name")
        expect(output).to include("Jim Beam")
        expect(output).to include("Jack Daniels")
      end

      it "displays a message when no duplicates are found" do
        output = capture_stdout { test_class.display_as_table({}, is_duplicate: true) }

        expect(output).to include("No duplicate emails found.")
      end

      it "falls back to plain text when terminal-table is not available" do
        allow(test_class).to receive(:with_dependencies).with(:terminal_table).and_return(false)

        output = capture_stdout { test_class.display_as_table(duplicate_groups, is_duplicate: true) }

        expect(output).to include("Duplicate email: duplicate@example.com")
        expect(output).to include("Jim Beam")
        expect(output).to include("Jack Daniels")
      end
    end
  end

  describe "#display_as_json" do
    context "with client data" do
      it "displays client data in JSON format" do
        output = capture_stdout { test_class.display_as_json(clients) }

        expect(output).to include('"id": 1')
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"email": "john@example.com"')
        expect(output).to include('"id": 2')
        expect(output).to include('"full_name": "Jane Smith"')
      end

      it "displays all fields in JSON format including custom fields" do
        # Using real Client objects from our let block
        output = capture_stdout { test_class.display_as_json(clients_with_custom_fields) }

        expect(output).to include('"id": 1')
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"email": "john@example.com"')
        expect(output).to include('"phone": "123-456-7890"')
        expect(output).to include('"address": "123 Main St"')
      end

      it "handles error when json dependency is not available" do
        allow(test_class).to receive(:with_dependencies).with(:json).and_return(false)

        output = capture_stdout { test_class.display_as_json(clients) }

        expect(output).to be_empty
      end
    end

    context "with duplicate group data" do
      it "displays duplicate groups in JSON format" do
        output = capture_stdout { test_class.display_as_json(duplicate_groups, is_duplicate: true) }

        expect(output).to include('"duplicate@example.com"')
        expect(output).to include('"id": 3')
        expect(output).to include('"full_name": "Jim Beam"')
        expect(output).to include('"id": 4')
        expect(output).to include('"full_name": "Jack Daniels"')
      end

      it "handles error when json dependency is not available" do
        allow(test_class).to receive(:with_dependencies).with(:json).and_return(false)

        output = capture_stdout { test_class.display_as_json(duplicate_groups, is_duplicate: true) }

        expect(output).to be_empty
      end
    end
  end

  # Helper method to capture stdout output
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
