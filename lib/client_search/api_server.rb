# frozen_string_literal: true

require "sinatra/base"
require "json"
require_relative "client_search"
require_relative "api_client"

module ClientSearch
  # REST API server for client search functionality
  # Provides HTTP endpoints for searching clients
  class ApiServer < Sinatra::Base
    # Enable CORS
    before do
      content_type :json
      headers "Access-Control-Allow-Origin" => "*",
              "Access-Control-Allow-Methods" => %w[GET OPTIONS]
    end

    get "/health" do
      { status: "ok", version: ClientSearch::VERSION }.to_json
    end

    # Search endpoint
    # GET /query?q=John&field=full_name
    get "/query" do
      query = params["q"]
      field = params["field"] || "full_name"

      if query.nil? || query.empty?
        status 400
        return { error: "Query parameter 'q' is required" }.to_json
      end

      begin
        search_service = ClientSearch.new(ApiClient.new)
        clients = search_service.search_by_field(query, field)

        # Convert clients to hash for JSON serialization
        client_data = clients.map(&:to_h)
        { results: client_data }.to_json
      rescue Error => e
        status 500
        { error: e.message }.to_json
      end
    end

    # Duplicates endpoint
    # GET /duplicates
    get "/duplicates" do
      search_service = ClientSearch.new(ApiClient.new)
      duplicate_groups = search_service.find_duplicate_emails

      # Convert the duplicate groups to a serializable format
      formatted_duplicates = {}
      duplicate_groups.each do |email, clients|
        formatted_duplicates[email] = clients.map(&:to_h)
      end

      { results: formatted_duplicates }.to_json
    rescue Error => e
      status 500
      { error: e.message }.to_json
    end
  end
end
