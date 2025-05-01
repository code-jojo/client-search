# frozen_string_literal: true

module ClientSearchCli
  module Api
    # Module for handling API responses and errors
    module ResponseHandling
      def handle_network_error(error)
        error_message = case error
                        when Errno::ECONNREFUSED then "Connection refused"
                        when Timeout::Error then "Network timeout"
                        when HTTParty::Error then "API returned invalid data"
                        else error.message
                        end
        puts "Error: #{error_message}"
        nil
      end

      def handle_response(response)
        if response.success?
          transform_client_data(response.parsed_response)
        else
          handle_error(response)
          nil
        end
      end

      def handle_error(response)
        message = case response.code
                  when 404 then "Resource not found (404)"
                  when 401 then "Unauthorized access (401)"
                  when 403 then "Forbidden access (403)"
                  when 500 then "Server error (500)"
                  else "API Error: #{response.code} - #{response.message}"
                  end
        puts "Error: #{message}"
      end

      def transform_client_data(clients)
        clients = [clients] unless clients.is_a?(Array)
        clients.map { |client| client.transform_keys(&:to_s) }
      end
    end
  end
end
