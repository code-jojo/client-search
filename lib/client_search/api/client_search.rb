# frozen_string_literal: true

module ClientSearch
  module Api
    # Module for client search functionality
    module ClientSearch
      def filter_clients_by_field(clients, field, search_query, search_parts)
        clients.select do |client|
          client_matches_search_by_field?(client, field, search_query, search_parts)
        end
      end

      def client_matches_search_by_field?(client, field, search_query, search_parts)
        return client_matches_search?(client, search_query, search_parts) if field == "full_name"

        field_value = get_field_value(client, field)
        return false unless field_value

        field_value = field_value.to_s.downcase
        field_value.include?(search_query) || field_parts_match?(field_value, search_parts)
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

        name_parts = full_name.split(/\s+/)

        name_parts.any? do |name_part|
          search_parts.any? { |search_part| name_matches_search_part?(name_part, search_part) }
        end
      end

      def name_matches_search_part?(name_part, search_part)
        name_part == search_part || name_part.start_with?(search_part)
      end
    end
  end
end
