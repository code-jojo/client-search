# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearch::CLI do
  subject(:cli) { described_class.new }

  let(:api_client) { instance_double(ClientSearch::ApiClient) }
  let(:search_service) { instance_double(ClientSearch::ClientSearch) }

  before do
    allow(ClientSearch::ApiClient).to receive(:new).and_return(api_client)
    allow(ClientSearch::ClientSearch).to receive(:new).with(api_client).and_return(search_service)
    # Set default options for all tests
    allow(cli).to receive(:options).and_return({ format: "table" })
  end

  describe "#version" do
    it "displays the version" do
      expect { cli.version }.to output(/client-search version #{ClientSearch::VERSION}/).to_stdout
    end
  end

  describe "#search" do
    context "when clients are found" do
      let(:client1) do
        instance_double(ClientSearch::Client,
                        id: 1,
                        full_name: "John Doe",
                        email: "john@example.com",
                        data: { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
                        to_h: { id: 1, full_name: "John Doe", email: "john@example.com" })
      end

      let(:client2) do
        instance_double(ClientSearch::Client,
                        id: 2,
                        full_name: "Jane Doe",
                        email: "jane@example.com",
                        data: { "id" => 2, "full_name" => "Jane Doe", "email" => "jane@example.com" },
                        to_h: { id: 2, full_name: "Jane Doe", email: "jane@example.com" })
      end

      before do
        allow(search_service).to receive(:search_by_field)
          .with("Doe", "full_name", any_args)
          .and_return([client1, client2])
        allow(search_service).to receive(:search_by_field)
          .with("john@example.com", "email", any_args)
          .and_return([client1])
        allow(search_service).to receive(:search_by_field)
          .with("John", "full_name", any_args)
          .and_return([client1])
        allow(search_service).to receive(:search_by_field)
          .with("1", "id", any_args)
          .and_return([client1])
      end

      it "searches for clients by name and displays them in a table by default" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })

        output = capture_stdout { cli.search("Doe") }

        expect(output).to include("John Doe")
        expect(output).to include("Jane Doe")
      end

      it "searches for clients by email when specified" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "email" })

        output = capture_stdout { cli.search("john@example.com") }

        expect(output).to include("John Doe")
        expect(output).not_to include("Jane Doe")
      end

      it "searches for clients by id when specified" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "id" })

        output = capture_stdout { cli.search("1") }

        expect(output).to include("John Doe")
        expect(output).not_to include("Jane Doe")
      end

      it "passes the custom file path to the ApiClient when specified" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name", file: "custom.json" })
        expect(ClientSearch::ApiClient).to receive(:new).with("custom.json").and_return(api_client)

        capture_stdout { cli.search("Doe") }
      end

      it "displays clients in JSON format when requested" do
        allow(cli).to receive(:options).and_return({ format: "json", field: "full_name" })

        output = capture_stdout { cli.search("Doe") }

        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"full_name": "Jane Doe"')
      end
    end

    context "when no clients are found" do
      before do
        allow(search_service).to receive(:search_by_field).with("NonExistent", "full_name", any_args).and_return([])
      end

      it "displays a message indicating no clients were found" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })
        output = capture_stdout { cli.search("NonExistent") }

        expect(output).to include("No results found.")
      end
    end

    context "when an error occurs" do
      before do
        allow(search_service).to receive(:search_by_field)
          .with("Error", "full_name", any_args)
          .and_raise(ClientSearch::Error, "API connection failed")
      end

      it "displays the error message and exits" do
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })
        expect { cli.search("Error") }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
      end
    end

    context "with edge case inputs" do
      it "handles empty search term" do
        allow(search_service).to receive(:search_by_field).with("", "full_name", any_args).and_return([])
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })

        output = capture_stdout { cli.search("") }

        expect(output).to include("No results found.")
      end

      it "handles nil search term" do
        allow(search_service).to receive(:search_by_field).with(nil, "full_name", any_args).and_return([])
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })

        output = capture_stdout { cli.search(nil) }

        expect(output).to include("No results found.")
      end

      it "handles search term with special characters" do
        allow(search_service).to receive(:search_by_field).with("O'Brien", "full_name", any_args).and_return([])
        allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })

        output = capture_stdout { cli.search("O'Brien") }

        expect(output).to include("No results found.")
      end
    end

    context "with invalid format option" do
      let(:client) do
        instance_double(ClientSearch::Client,
                        id: 1,
                        full_name: "John Doe",
                        email: "john@example.com",
                        data: { "id" => 1, "full_name" => "John Doe", "email" => "john@example.com" },
                        to_h: { id: 1, full_name: "John Doe", email: "john@example.com" })
      end

      before do
        allow(search_service).to receive(:search_by_field).with("John", "full_name", any_args).and_return([client])
      end

      it "defaults to table format when an invalid format is specified" do
        allow(cli).to receive(:options).and_return({ format: "invalid_format", field: "full_name" })

        output = capture_stdout { cli.search("John") }

        expect(output).to include("John Doe") # Table format output
      end
    end

    context "with various network errors" do
      [
        "Connection refused",
        "Network timeout",
        "API returned invalid data",
        "Authentication failure"
      ].each do |error_message|
        it "handles #{error_message} error" do
          allow(search_service).to receive(:search_by_field)
            .with("Network", "full_name", any_args)
            .and_raise(ClientSearch::Error, error_message)
          allow(cli).to receive(:options).and_return({ format: "table", field: "full_name" })

          expect { cli.search("Network") }.to output(/Error: #{error_message}/).to_stdout.and raise_error(SystemExit)
        end
      end
    end
  end

  describe "#duplicates" do
    context "when duplicate emails are found" do
      let(:client1) do
        instance_double(ClientSearch::Client,
                        id: 1,
                        full_name: "John Doe",
                        email: "duplicate@example.com",
                        data: { "id" => 1, "full_name" => "John Doe", "email" => "duplicate@example.com" },
                        to_h: { id: 1, full_name: "John Doe", email: "duplicate@example.com" })
      end

      let(:client2) do
        instance_double(ClientSearch::Client,
                        id: 2,
                        full_name: "Jane Smith",
                        email: "duplicate@example.com",
                        data: { "id" => 2, "full_name" => "Jane Smith", "email" => "duplicate@example.com" },
                        to_h: { id: 2, full_name: "Jane Smith", email: "duplicate@example.com" })
      end

      let(:client3) do
        instance_double(ClientSearch::Client,
                        id: 3,
                        full_name: "Another Person",
                        email: "another.duplicate@example.com",
                        data: { "id" => 3, "full_name" => "Another Person",
                                "email" => "another.duplicate@example.com" },
                        to_h: { id: 3, full_name: "Another Person", email: "another.duplicate@example.com" })
      end

      let(:client4) do
        instance_double(ClientSearch::Client,
                        id: 4,
                        full_name: "One More",
                        email: "another.duplicate@example.com",
                        data: { "id" => 4, "full_name" => "One More", "email" => "another.duplicate@example.com" },
                        to_h: { id: 4, full_name: "One More", email: "another.duplicate@example.com" })
      end

      let(:duplicate_groups) do
        {
          "duplicate@example.com" => [client1, client2],
          "another.duplicate@example.com" => [client3, client4]
        }
      end

      before do
        allow(search_service).to receive(:find_duplicate_emails).and_return(duplicate_groups)
      end

      it "displays duplicate emails in a table by default" do
        allow(cli).to receive(:options).and_return({ format: "table" })

        output = capture_stdout { cli.duplicates }

        expect(output).to include("John Doe")
        expect(output).to include("Jane Smith")
        expect(output).to include("Another Person")
        expect(output).to include("One More")
      end

      it "uses custom file when specified" do
        allow(cli).to receive(:options).and_return({ format: "table", file: "custom.json" })
        expect(ClientSearch::ApiClient).to receive(:new).with("custom.json").and_return(api_client)

        capture_stdout { cli.duplicates }
      end

      it "displays duplicate emails in JSON format when requested" do
        allow(cli).to receive(:options).and_return({ format: "json" })

        output = capture_stdout { cli.duplicates }

        expect(output).to include('"duplicate@example.com"')
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"full_name": "Jane Smith"')
        expect(output).to include('"another.duplicate@example.com"')
      end
    end

    context "when no duplicate emails are found" do
      before do
        allow(search_service).to receive(:find_duplicate_emails).and_return({})
      end

      it "displays a message indicating no duplicates were found" do
        output = capture_stdout { cli.duplicates }

        expect(output).to include("No duplicate emails found.")
      end
    end

    context "when an error occurs" do
      before do
        allow(search_service).to receive(:find_duplicate_emails).and_raise(ClientSearch::Error,
                                                                           "API connection failed")
      end

      it "displays the error message and exits" do
        expect { cli.duplicates }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
      end
    end
  end

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
