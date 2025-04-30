# frozen_string_literal: true

require "thor"
require "httparty"
require "csv"
require "terminal-table"

module ClientSearchCli
  class CLI < Thor
    desc "search NAME", "Search for clients by name"
    method_option :format, type: :string, default: "table", desc: "Output format (table, json, csv)"

    # Search for clients by name
    #
    # @param name [String] The name to search for
    # @return [void]
    def search(name)
      puts "Searching for clients with name: #{name}"
      
      begin
        api_client = ApiClient.new
        search_service = ClientSearch.new(api_client)
        
        clients = search_service.search_by_name(name)
        
        if clients.empty?
          puts "No clients found matching name '#{name}'"
        else
          display_clients(clients, options[:format])
        end
      rescue Error => e
        puts "Error: #{e.message}"
        exit 1
      end
    end

    desc "version", "Display the version of the client-search-cli"
    def version
      puts "client-search-cli version #{ClientSearchCli::VERSION}"
    end
    
    private
    
    # Display clients in the specified format
    #
    # @param clients [Array<Client>] The clients to display
    # @param format [String] The format to display the clients in
    # @return [String] The formatted string
    def display_clients(clients, format)
      case format.downcase
      when "json"
        display_as_json(clients)
      when "csv"
        display_as_csv(clients)
      else # default to table
        display_as_table(clients)
      end
    end
    
    # Display clients as a table
    #
    # @param clients [Array<Client>] The clients to display
    # @return [String] The table string
    def display_as_table(clients)
      puts "Found #{clients.size} client(s):"
      
      begin
        require "terminal-table"
        table = Terminal::Table.new do |t|
          t.headings = ['ID', 'Full Name', 'Email']
          
          clients.each do |client|
            t.add_row [
              client.id,
              client.full_name,
              client.email || 'N/A',
            ]
          end
        end
        
        puts table
      rescue LoadError, NameError => e
        puts "ID\tFull Name\tEmail"
        puts "-" * 80
        
        clients.each do |client|
          puts "#{client.id}\t#{client.full_name}\t#{client.email || 'N/A'}"
        end
      end
    end
    
    # Display clients as JSON
    #
    # @param clients [Array<Client>] The clients to display
    # @return [String] The JSON string
    def display_as_json(clients)
      require "json"
      client_data = clients.map(&:to_h)
      puts JSON.pretty_generate(client_data)
    end
    
    # Display clients as CSV
    #
    # @param clients [Array<Client>] The clients to display
    # @return [String] The CSV string
    def display_as_csv(clients)
      require "csv"
      headers = ["ID", "Full Name", "Email"]
      
      csv_string = CSV.generate do |csv|
        csv << headers
        clients.each do |client|
          csv << [client.id, client.full_name, client.email]
        end
      end
      
      puts csv_string
    end
  end
end 