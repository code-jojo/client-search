# frozen_string_literal: true

require "thor"
require "httparty"
require "csv"
require "terminal-table"

module ClientSearchCli
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

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
        
        clients = search_service.search_by_name(name, options.to_h)
        
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

    desc "duplicates", "Find clients with duplicate emails"
    method_option :format, type: :string, default: "table", desc: "Output format (table, json, csv)"
    
    # Find and display clients with duplicate emails
    #
    # @return [void]
    def duplicates
      puts "Searching for clients with duplicate emails..."
      
      begin
        api_client = ApiClient.new
        search_service = ClientSearch.new(api_client)
        
        duplicate_groups = search_service.find_duplicate_emails
        
        if duplicate_groups.empty?
          puts "No duplicate emails found"
        else
          display_duplicate_emails(duplicate_groups, options[:format])
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
    
    # Display duplicate email groups in the specified format
    #
    # @param duplicate_groups [Hash<String, Array<Client>>] Groups of clients with duplicate emails
    # @param format [String] The format to display the clients in
    # @return [void]
    def display_duplicate_emails(duplicate_groups, format)
      puts "Found #{duplicate_groups.size} email(s) with duplicates:"
      
      case format.downcase
      when "json"
        display_duplicates_as_json(duplicate_groups)
      when "csv"
        display_duplicates_as_csv(duplicate_groups)
      else # default to table
        display_duplicates_as_table(duplicate_groups)
      end
    end
    
    # Display duplicate email groups as a table
    #
    # @param duplicate_groups [Hash<String, Array<Client>>] Groups of clients with duplicate emails
    # @return [void]
    def display_duplicates_as_table(duplicate_groups)
      duplicate_groups.each do |email, clients|
        puts "\nDuplicate Email: #{email} (#{clients.size} occurrences)"
        
        begin
          require "terminal-table"
          table = Terminal::Table.new do |t|
            t.headings = ['ID', 'Full Name']
            clients.each do |client|
              t.add_row [client.id, client.full_name]
            end
          end
          
          puts table
        rescue LoadError, NameError => e
          puts "ID\tFull Name"
          puts "-" * 40
          
          clients.each do |client|
            puts "#{client.id}\t#{client.full_name}"
          end
        end
      end
    end
    
    # Display duplicate email groups as JSON
    #
    # @param duplicate_groups [Hash<String, Array<Client>>] Groups of clients with duplicate emails
    # @return [void]
    def display_duplicates_as_json(duplicate_groups)
      require "json"
      
      formatted_data = duplicate_groups.transform_values do |clients|
        clients.map(&:to_h)
      end
      
      puts JSON.pretty_generate(formatted_data)
    end
    
    # Display duplicate email groups as CSV
    #
    # @param duplicate_groups [Hash<String, Array<Client>>] Groups of clients with duplicate emails 
    # @return [void]
    def display_duplicates_as_csv(duplicate_groups)
      require "csv"
      
      csv_string = CSV.generate do |csv|
        csv << ["Email", "ID", "Full Name"]
        
        duplicate_groups.each do |email, clients|
          clients.each do |client|
            csv << [email, client.id, client.full_name]
          end
        end
      end
      
      puts csv_string
    end
    
    # Display clients as a table
    #
    # @param clients [Array<Client>] The clients to display
    # @return [void]
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