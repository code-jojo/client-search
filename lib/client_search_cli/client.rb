# frozen_string_literal: true

module ClientSearchCli
  # Represents a client entity with identification and contact information
  # Provides methods for initialization from various data sources and serialization
  class Client
    attr_reader :id, :full_name, :email

    def initialize(data)
      data ||= {}
      @id = data["id"]
      @full_name = data["full_name"] || ""
      @email = data["email"]
    end

    def name
      full_name.to_s.strip.then { |n| n.empty? && email ? email : n }
    end

    def to_h
      {
        id: id,
        full_name: full_name,
        email: email
      }
    end
  end
end
