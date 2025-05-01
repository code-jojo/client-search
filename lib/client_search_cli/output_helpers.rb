# frozen_string_literal: true

require "terminal-table"
require "json"

module ClientSearchCli
  # Helper module for displaying and formatting client data in various output formats
  # Provides methods for rendering data as tables, plain text, and JSON
  module OutputHelpers
    # Display data in table format or fallback to plain text
    def display_as_table(data, is_duplicate: false)
      if data.empty?
        puts is_duplicate ? "No duplicate emails found." : "No results found."
        return
      end

      if is_duplicate
        with_dependencies(:terminal_table) do
          render_duplicate_tables(data)
        end || display_as_plain_text(data, is_duplicate: true)
      else
        with_dependencies(:terminal_table) do
          render_client_table(data)
        end || display_as_plain_text(data, is_duplicate: false)
      end
    end

    # Display data in JSON format
    def display_as_json(data, is_duplicate: false)
      with_dependencies(:json) do
        formatted_data = if is_duplicate
                           data.transform_values { |clients| clients.map(&:to_h) }
                         else
                           data.map(&:to_h)
                         end
        puts JSON.pretty_generate(formatted_data)
      end
    end

    private

    # Safely load dependencies and execute block if successful
    def with_dependencies(*dependencies)
      dependencies.each { |dep| require dep.to_s }
      yield if block_given?
      true
    rescue LoadError, NameError
      false
    end

    def render_duplicate_tables(duplicate_groups)
      duplicate_groups.each do |email, clients|
        puts "\nDuplicate email: #{email}"
        table = Terminal::Table.new do |t|
          t.headings = ["ID", "Full Name"]
          clients.each { |client| t.add_row [client.id, client.full_name] }
        end
        puts table
      end
    end

    def render_client_table(clients)
      table = Terminal::Table.new do |t|
        t.headings = ["ID", "Full Name", "Email"]
        clients.each do |client|
          t.add_row [client.id, client.full_name, client.email || "N/A"]
        end
      end
      puts table
    end

    def display_as_plain_text(data, is_duplicate: false)
      is_duplicate ? display_duplicate_groups_plain_text(data) : display_clients_as_plain_text(data)
    end

    def display_clients_as_plain_text(clients)
      puts "ID\tFull Name\tEmail"
      puts "-" * 40
      clients.each do |client|
        puts "#{client.id}\t#{client.full_name}\t#{client.email || "N/A"}"
      end
    end

    def display_duplicate_groups_plain_text(duplicate_groups)
      duplicate_groups.each do |email, clients|
        puts "\nDuplicate email: #{email}"
        puts "ID\tFull Name"
        puts "-" * 30
        clients.each do |client|
          puts "#{client.id}\t#{client.full_name}"
        end
      end
    end
  end
end
