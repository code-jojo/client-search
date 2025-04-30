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
        allow(search_service).to receive(:search_by_name).with("Doe", any_args).and_return(clients)
      end
      
      it "searches for clients by name and displays them in a table by default" do
        allow(cli).to receive(:options).and_return({ format: "table" })
        
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include("Found 2 client(s)")
        expect(output).to include("John Doe")
        expect(output).to include("Jane Doe")
      end
      
      it "displays clients in JSON format when requested" do
        allow(cli).to receive(:options).and_return({ format: "json" })
        
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"full_name": "Jane Doe"')
      end
      
      it "displays clients in CSV format when requested" do
        allow(cli).to receive(:options).and_return({ format: "csv" })
        
        output = capture_stdout { cli.search("Doe") }
        
        expect(output).to include("Searching for clients with name: Doe")
        expect(output).to include("ID,Full Name,Email")
        expect(output).to include("1,John Doe,john@example.com")
        expect(output).to include("2,Jane Doe,jane@example.com")
      end
    end
    
    context "when no clients are found" do
      before do
        allow(search_service).to receive(:search_by_name).with("NonExistent", any_args).and_return([])
      end
      
      it "displays a message indicating no clients were found" do
        output = capture_stdout { cli.search("NonExistent") }
        
        expect(output).to include("Searching for clients with name: NonExistent")
        expect(output).to include("No clients found matching name 'NonExistent'")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(search_service).to receive(:search_by_name).with("Error", any_args).and_raise(ClientSearchCli::Error, "API connection failed")
      end
      
      it "displays the error message and exits" do
        expect { cli.search("Error") }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
      end
    end

    context "with edge case inputs" do
      it "handles empty search term" do
        allow(search_service).to receive(:search_by_name).with("", any_args).and_return([])
        
        output = capture_stdout { cli.search("") }
        
        expect(output).to include("Searching for clients with name: ")
        expect(output).to include("No clients found matching name ''")
      end

      it "handles nil search term" do
        allow(search_service).to receive(:search_by_name).with(nil, any_args).and_return([])
        
        output = capture_stdout { cli.search(nil) }
        
        expect(output).to include("Searching for clients with name: ")
        expect(output).to include("No clients found matching name ''")
      end

      it "handles search term with special characters" do
        allow(search_service).to receive(:search_by_name).with("O'Brien", any_args).and_return([])
        
        output = capture_stdout { cli.search("O'Brien") }
        
        expect(output).to include("Searching for clients with name: O'Brien")
      end
    end

    context "with invalid format option" do
      let(:client) do
        instance_double("ClientSearchCli::Client", 
          id: 1, 
          full_name: "John Doe", 
          email: "john@example.com",
          to_h: { id: 1, full_name: "John Doe", email: "john@example.com" }
        )
      end
      
      before do
        allow(search_service).to receive(:search_by_name).with("John", any_args).and_return([client])
      end
      
      it "defaults to table format when an invalid format is specified" do
        allow(cli).to receive(:options).and_return({ format: "invalid_format" })
        
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
          allow(search_service).to receive(:search_by_name).with("Network", any_args).and_raise(ClientSearchCli::Error, error_message)
          
          expect { cli.search("Network") }.to output(/Error: #{error_message}/).to_stdout.and raise_error(SystemExit)
        end
      end
    end
  end
  
  describe "#duplicates" do
    context "when duplicate emails are found" do
      let(:client1) do
        instance_double("ClientSearchCli::Client",
          id: 1,
          full_name: "John Doe",
          email: "duplicate@example.com",
          to_h: { id: 1, full_name: "John Doe", email: "duplicate@example.com" }
        )
      end
      
      let(:client2) do
        instance_double("ClientSearchCli::Client",
          id: 2,
          full_name: "Jane Smith",
          email: "duplicate@example.com",
          to_h: { id: 2, full_name: "Jane Smith", email: "duplicate@example.com" }
        )
      end
      
      let(:client3) do
        instance_double("ClientSearchCli::Client",
          id: 3,
          full_name: "Another Person",
          email: "another.duplicate@example.com",
          to_h: { id: 3, full_name: "Another Person", email: "another.duplicate@example.com" }
        )
      end
      
      let(:client4) do
        instance_double("ClientSearchCli::Client",
          id: 4,
          full_name: "One More",
          email: "another.duplicate@example.com",
          to_h: { id: 4, full_name: "One More", email: "another.duplicate@example.com" }
        )
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
        
        expect(output).to include("Searching for clients with duplicate emails")
        expect(output).to include("Found 2 email(s) with duplicates")
        expect(output).to include("Duplicate Email: duplicate@example.com (2 occurrences)")
        expect(output).to include("John Doe")
        expect(output).to include("Jane Smith")
        expect(output).to include("Duplicate Email: another.duplicate@example.com (2 occurrences)")
        expect(output).to include("Another Person")
        expect(output).to include("One More")
      end
      
      it "displays duplicate emails in JSON format when requested" do
        allow(cli).to receive(:options).and_return({ format: "json" })
        
        output = capture_stdout { cli.duplicates }
        
        expect(output).to include("Searching for clients with duplicate emails")
        expect(output).to include("Found 2 email(s) with duplicates")
        expect(output).to include('"duplicate@example.com"')
        expect(output).to include('"full_name": "John Doe"')
        expect(output).to include('"full_name": "Jane Smith"')
        expect(output).to include('"another.duplicate@example.com"')
      end
      
      it "displays duplicate emails in CSV format when requested" do
        allow(cli).to receive(:options).and_return({ format: "csv" })
        
        output = capture_stdout { cli.duplicates }
        
        expect(output).to include("Searching for clients with duplicate emails")
        expect(output).to include("Found 2 email(s) with duplicates")
        expect(output).to include("Email,ID,Full Name")
        expect(output).to include("duplicate@example.com,1,John Doe")
        expect(output).to include("duplicate@example.com,2,Jane Smith")
        expect(output).to include("another.duplicate@example.com,3,Another Person")
        expect(output).to include("another.duplicate@example.com,4,One More")
      end
    end
    
    context "when no duplicate emails are found" do
      before do
        allow(search_service).to receive(:find_duplicate_emails).and_return({})
      end
      
      it "displays a message indicating no duplicates were found" do
        output = capture_stdout { cli.duplicates }
        
        expect(output).to include("Searching for clients with duplicate emails")
        expect(output).to include("No duplicate emails found")
      end
    end
    
    context "when an error occurs" do
      before do
        allow(search_service).to receive(:find_duplicate_emails).and_raise(ClientSearchCli::Error, "API connection failed")
      end
      
      it "displays the error message and exits" do
        expect { cli.duplicates }.to output(/Error: API connection failed/).to_stdout.and raise_error(SystemExit)
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