# frozen_string_literal: true

require "thor"
require "httparty"
require "csv"

module ClientSearchCli
  # CLI command parser using Thor
  class CLI < Thor
    desc "search NAME", "Search for clients by name"
    method_option :format, type: :string, default: "table", desc: "Output format (table, json, csv)"
    method_option :api_key, type: :string, desc: "ShiftCare API key (default: uses SHIFTCARE_API_KEY env var)"
    method_option :limit, type: :numeric, desc: "Maximum number of results to return"
    method_option :exact, type: :boolean, default: false, desc: "Require exact name match"
    def search(name)
      puts "Searching for clients with name: #{name}"
      
      begin
        api_client = ApiClient.new(options[:api_key])
        search_service = ClientSearch.new(api_client)
        
        search_options = {}
        search_options[:limit] = options[:limit] if options[:limit]
        search_options[:exact] = true if options[:exact]
        
        clients = search_service.search_by_name(name, search_options)
        
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
    
    def display_as_table(clients)
      puts "Found #{clients.size} client(s):"
      puts "ID\tName\tEmail\tPhone"
      puts "-" * 50
      clients.each do |client|
        puts "#{client.id}\t#{client.name}\t#{client.email || 'N/A'}\t#{client.phone || 'N/A'}"
      end
    end
    
    def display_as_json(clients)
      require "json"
      client_data = clients.map(&:to_h)
      puts JSON.pretty_generate(client_data)
    end
    
    def display_as_csv(clients)
      require "csv"
      headers = ["ID", "Name", "Email", "Phone", "Address", "Notes"]
      
      csv_string = CSV.generate do |csv|
        csv << headers
        clients.each do |client|
          csv << [client.id, client.name, client.email, client.phone, client.address, client.notes]
        end
      end
      
      puts csv_string
    end
  end
end 