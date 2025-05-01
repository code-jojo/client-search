# frozen_string_literal: true

require "terminal-table"
require "json"
require_relative "output/table_formatting"
require_relative "output/formatting_helpers"

module ClientSearchCli
  # Helper module for displaying and formatting client data in various output formats
  # Provides methods for rendering data as tables, plain text, and JSON
  module OutputHelpers
    include Output::TableFormatting
    include Output::FormattingHelpers

    def display_as_table(data, is_duplicate: false)
      if data.empty?
        puts is_duplicate ? "No duplicate emails found." : "No results found."
        return
      end

      if is_duplicate
        display_duplicate_table(data)
      else
        display_client_table(data)
      end
    end

    def display_duplicate_table(data)
      with_dependencies(:terminal_table) do
        render_duplicate_tables(data)
      end || display_as_plain_text(data, is_duplicate: true)
    end

    def display_client_table(data)
      with_dependencies(:terminal_table) do
        render_client_table(data)
      end || display_as_plain_text(data, is_duplicate: false)
    end

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
  end
end
