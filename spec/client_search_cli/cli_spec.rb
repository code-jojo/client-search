# frozen_string_literal: true

RSpec.describe ClientSearchCli::CLI do
  let(:api_client) { instance_double("ClientSearchCli::ApiClient") }
  let(:search_service) { instance_double("ClientSearchCli::ClientSearch") }
  let(:cli) { described_class.new }
  
  before do
    allow(ClientSearchCli::ApiClient).to receive(:new).and_return(api_client)
    allow(ClientSearchCli::ClientSearch).to receive(:new).with(api_client).and_return(search_service)
    # Default stub for the most common case with empty options hash
    allow(search_service).to receive(:search_by_name).with(any_args).and_return([])
  end
  
  describe "#version" do
    it "displays the version" do
      expect { cli.version }.to output(/client-search-cli version #{ClientSearchCli::VERSION}/).to_stdout
    end
  end
  
  describe "#search" do
    context "when clients are found" do
      let(:clients) do
        [
          instance_double("ClientSearchCli::Client", 
            id: 1, 
            full_name: "John Doe", 
            email: "john@example.com",
            to_h: { id: 1, full_name: "John Doe", email: "john@example.com" }
          ),
          instance_double("ClientSearchCli::Client", 
            id: 2, 
            full_name: "Jane Doe", 
            email: "jane@example.com",
            to_h: { id: 2, full_name: "Jane Doe", email: "jane@example.com" }
          )
        ]
      end
      
      before do
        allow(search_service).to receive(:search_by_name).with("Doe", {}).and_return(clients)
      end
      
      it "searches for clients by name and displays them in a table by default" do
        cli = described_class.new([], { format: "table" })
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include("Found 2 client(s)")
        expect(output).to include("John Doe")
        expect(output).to include("Jane Doe")
      end
      
      it "displays clients in JSON format when requested" do
        cli = described_class.new([], { format: "json" })
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"full_name": "Jane Doe"')
      end
      
      it "displays clients in CSV format when requested" do
        cli = described_class.new([], { format: "csv" })
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include("ID,Full Name,Email")
        expect(output).to include("1,John Doe,john@example.com")
        expect(output).to include("2,Jane Doe,jane@example.com")
      end

      context "with limit option" do
        it "passes limit option to search service" do
          cli = described_class.new([], { format: "table", limit: 1 })
          
          # Create a subset of clients for the limit
          limited_clients = clients.take(1)
          allow(search_service).to receive(:search_by_name).with("Doe", {limit: 1}).and_return(limited_clients)
          
          output = capture_stdout { cli.search("Doe") }
          
          expect(output).to include("Found 1 client(s)")
          expect(output).to include("John Doe")
          expect(output).not_to include("Jane Doe")
        end
      end

      context "with exact option" do
        it "passes exact option to search service" do
          cli = described_class.new([], { format: "table", exact: true })
          allow(search_service).to receive(:search_by_name).with("Doe", {exact: true}).and_return(clients)
          
          capture_stdout { cli.search("Doe") }
          expect(search_service).to have_received(:search_by_name).with("Doe", {exact: true})
        end
      end

      context "with both limit and exact options" do
        it "passes both options to search service" do
          cli = described_class.new([], { format: "table", limit: 1, exact: true })
          limited_clients = clients.take(1)
          allow(search_service).to receive(:search_by_name).with("Doe", {limit: 1, exact: true}).and_return(limited_clients)
          
          capture_stdout { cli.search("Doe") }
          expect(search_service).to have_received(:search_by_name).with("Doe", {limit: 1, exact: true})
        end
      end
    end
    
    context "when no clients are found" do
      before do
        allow(search_service).to receive(:search_by_name).with("NonExistent", {}).and_return([])
      end
      
      it "displays a message indicating no clients were found" do
        cli = described_class.new([], { format: "table" })
        output = capture_stdout { cli.search("NonExistent") }
        
        expect(output).to include("Searching for clients with name: NonExistent")
        expect(output).to include("No clients found matching name 'NonExistent'")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(search_service).to receive(:search_by_name).with("Error", {}).and_raise(ClientSearchCli::Error, "API connection failed")
      end
      
      it "displays the error message and exits" do
        cli = described_class.new([], { format: "table" })
        expect { cli.search("Error") }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
      end
    end

    context "with edge case inputs" do
      it "handles empty search term" do
        allow(search_service).to receive(:search_by_name).with("", {}).and_return([])
        
        cli = described_class.new([], { format: "table" })
        output = capture_stdout { cli.search("") }
        
        expect(output).to include("Searching for clients with name: ")
        expect(output).to include("No clients found matching name ''")
      end

      it "handles nil search term" do
        allow(search_service).to receive(:search_by_name).with(nil, {}).and_return([])
        
        cli = described_class.new([], { format: "table" })
        output = capture_stdout { cli.search(nil) }
        
        expect(output).to include("Searching for clients with name: ")
        expect(output).to include("No clients found matching name ''")
      end

      it "handles search term with special characters" do
        allow(search_service).to receive(:search_by_name).with("O'Brien", {}).and_return([])
        
        cli = described_class.new([], { format: "table" })
        output = capture_stdout { cli.search("O'Brien") }
        
        expect(output).to include("Searching for clients with name: O'Brien")
      end
    end

    context "with invalid format option" do
      it "defaults to table format when an invalid format is specified" do
        client = instance_double("ClientSearchCli::Client", 
          id: 1, 
          full_name: "John Doe", 
          email: "john@example.com",
          to_h: { id: 1, full_name: "John Doe", email: "john@example.com" }
        )
        
        allow(search_service).to receive(:search_by_name).with("John", {}).and_return([client])
        
        cli = described_class.new([], { format: "invalid_format" })
        output = capture_stdout { cli.search("John") }
        
        expect(output).to include("Found 1 client(s)")
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
          allow(search_service).to receive(:search_by_name).with("Network", {}).and_raise(ClientSearchCli::Error, error_message)
          
          cli = described_class.new([], { format: "table" })
          expect { cli.search("Network") }.to output(/Error: #{error_message}/).to_stdout.and raise_error(SystemExit)
        end
      end
    end
  end
  
  # Helper method to capture stdout
  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end 