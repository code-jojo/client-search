# frozen_string_literal: true

RSpec.describe ClientSearchCli::CLI do
  let(:api_client) { instance_double("ClientSearchCli::ApiClient") }
  let(:search_service) { instance_double("ClientSearchCli::ClientSearch") }
  let(:cli) { described_class.new }
  
  before do
    allow(ClientSearchCli::ApiClient).to receive(:new).and_return(api_client)
    allow(ClientSearchCli::ClientSearch).to receive(:new).with(api_client).and_return(search_service)
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
        allow(search_service).to receive(:search_by_name).with("Doe").and_return(clients)
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
    end
    
    context "when no clients are found" do
      before do
        allow(search_service).to receive(:search_by_name).with("NonExistent").and_return([])
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
        allow(search_service).to receive(:search_by_name).with("Error").and_raise(ClientSearchCli::Error, "API connection failed")
      end
      
      it "displays the error message and exits" do
        cli = described_class.new([], { format: "table" })
        expect { cli.search("Error") }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
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