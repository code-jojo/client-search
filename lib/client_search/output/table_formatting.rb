# frozen_string_literal: true

require "terminal-table"

module ClientSearch
  module Output
    # Module for formatting and displaying data in tables
    module TableFormatting
      def render_client_table(clients)
        return if clients.empty?

        fields = determine_display_fields(clients.first)
        headings = format_headings(fields)

        table = Terminal::Table.new do |t|
          t.headings = headings
          clients.each do |client|
            t.add_row(extract_client_values(client, fields))
          end
        end
        puts table
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
    end
  end
end
