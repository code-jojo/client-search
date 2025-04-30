# frozen_string_literal: true

RSpec.describe ClientSearchCli::OutputHelpers do
  let(:test_class) do
    Class.new do
      include ClientSearchCli::OutputHelpers

      # Expose private method for testing
      def test_with_dependencies(*dependencies, &block)
        with_dependencies(*dependencies, &block)
      end
    end.new
  end

  let(:clients) do
    [
      instance_double("ClientSearchCli::Client",
                      id: 1,
                      full_name: "John Doe",
                      email: "john@example.com",
                      to_h: { id: 1, full_name: "John Doe", email: "john@example.com" }),
      instance_double("ClientSearchCli::Client",
                      id: 2,
                      full_name: "Jane Smith",
                      email: "jane@example.com",
                      to_h: { id: 2, full_name: "Jane Smith", email: "jane@example.com" })
    ]
  end

  let(:duplicate_groups) do
    {
      "duplicate@example.com" => [
        instance_double("ClientSearchCli::Client",
                        id: 3,
                        full_name: "Jim Beam",
                        email: "duplicate@example.com",
                        to_h: { id: 3, full_name: "Jim Beam", email: "duplicate@example.com" }),
        instance_double("ClientSearchCli::Client",
                        id: 4,
                        full_name: "Jack Daniels",
                        email: "duplicate@example.com",
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

  describe "#display_as_table" do
    context "with client data" do
      it "displays client data in a table format" do
        output = capture_stdout { test_class.display_as_table(clients) }

        expect(output).to include("ID")
        expect(output).to include("Full Name")
        expect(output).to include("Email")
        expect(output).to include("John Doe")
        expect(output).to include("Jane Smith")
      end

      it "displays a message when no clients are found" do
        output = capture_stdout { test_class.display_as_table([]) }

        expect(output).to include("No results found.")
      end

      it "falls back to plain text when terminal-table is not available" do
        allow(test_class).to receive(:with_dependencies).with(:terminal_table).and_return(false)

        output = capture_stdout { test_class.display_as_table(clients) }

        expect(output).to include("ID\tFull Name\tEmail")
        expect(output).to include("John Doe")
        expect(output).to include("jane@example.com")
      end

      it "handles clients with nil emails" do
        client_with_nil_email = instance_double("ClientSearchCli::Client",
                                                id: 5,
                                                full_name: "No Email",
                                                email: nil,
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
