# frozen_string_literal: true

module ClientSearch
  module Api
    # Module for client search functionality
    module ClientSearch
      def filter_clients_by_field(clients, field, search_query, search_parts)
        field_downcase = field.to_s.downcase

        return filter_by_name(clients, search_query, search_parts) if %w[full_name name].include?(field_downcase)

        # Regular search for other fields
        clients.select do |client|
          client_matches_search_by_field?(client, field, search_query, search_parts)
        end
      end

      def filter_by_name(clients, search_query, search_parts)
        # For multiple word searches - John Doe
        if search_query.include?(" ")
          exact_matches = find_exact_matches(clients, search_query)
          return exact_matches unless exact_matches.empty?

          return find_all_parts_matches(clients, search_parts)
        end

        # For single word name searches - John
        return find_single_word_matches(clients, search_parts.first) if search_parts.size == 1

        # Fallback to standard matching
        clients.select do |client|
          client_matches_search_by_field?(client, "full_name", search_query, search_parts)
        end
      end

      def find_exact_matches(clients, search_query)
        clients.select do |client|
          client_value = (client["full_name"] || "").downcase
          client_value == search_query
        end
      end

      def find_all_parts_matches(clients, search_parts)
        clients.select do |client|
          client_value = (client["full_name"] || "").downcase
          all_search_parts_in_name?(client_value, search_parts)
        end
      end

      def find_single_word_matches(clients, search_word)
        clients.select do |client|
          client_value = (client["full_name"] || "").downcase
          name_parts = client_value.split(/[\s\-]+/)
          name_parts.any? { |part| part == search_word }
        end
      end

      def client_matches_search_by_field?(client, field, search_query, search_parts)
        return client_matches_search?(client, search_query, search_parts) if field.to_s.downcase == "full_name"

        field_value = get_field_value(client, field)
        return false unless field_value

        field_value = field_value.to_s.downcase
        field_value == search_query ||
          field_value.include?(search_query) ||
          field_parts_match?(field_value, search_parts)
      end

      def field_parts_match?(field_value, search_parts)
        field_parts = field_value.split(/\s+/)

        field_parts.any? do |field_part|
          search_parts.any? do |search_part|
            field_part == search_part || field_part.start_with?(search_part)
          end
        end
      end

      def get_field_value(client, field)
        # Maps common field name variations (e.g. "e-mail", "mail") to standard keys
        case field.to_s.downcase
        when "name", "full_name"
          client["full_name"]
        when "email", "mail", "e-mail", "e_mail"
          client["email"]
        else
          client[field] || client[field.to_s.downcase] || client[field.to_sym]
        end
      end

      def client_matches_search?(client, search_query, search_parts)
        full_name = (client["full_name"] || "").downcase
        email = (client["email"] || "").downcase

        match_name_or_email?(full_name, email, search_query, search_parts)
      end

      def match_name_or_email?(full_name, email, search_query, search_parts)
        exact_name_match?(full_name, search_query) ||
          email_contains_query?(email, search_query) ||
          name_parts_match?(full_name, search_parts)
      end

      def exact_name_match?(full_name, search_query)
        full_name == search_query
      end

      def email_contains_query?(email, search_query)
        email.include?(search_query)
      end

      def name_parts_match?(full_name, search_parts)
        return false if full_name.empty? || search_parts.empty?

        name_parts = full_name.split(/[\s\-]+/)

        name_parts.any? do |name_part|
          search_parts.any? { |search_part| name_matches_search_part?(name_part, search_part) }
        end
      end

      def all_search_parts_in_name?(full_name, search_parts)
        return false if full_name.empty? || search_parts.empty?

        search_parts.all? do |search_part|
          # Check if it exists as a whole word
          full_name.split(/[\s\-]+/).any? { |part| part == search_part }
        end
      end

      def name_matches_search_part?(name_part, search_part)
        name_part == search_part || name_part.start_with?(search_part)
      end
    end
  end
end
