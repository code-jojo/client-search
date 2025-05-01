# frozen_string_literal: true

module ClientSearchCli
  # Represents a client entity with identification and contact information
  # Provides methods for initialization from various data sources and serialization
  class Client
    attr_reader :id, :full_name, :email, :data

    def initialize(data)
      data ||= {}
      @data = data.transform_keys(&:to_s)
      @id = @data["id"]
      @full_name = @data["full_name"] || @data["name"] || ""
      @email = @data["email"]
    end

    def name
      full_name.to_s.strip.then { |n| n.empty? && email ? email : n }
    end

    def to_h
      @data
    end

    def method_missing(method_name, *args)
      return @data[method_name.to_s] if @data.key?(method_name.to_s)

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      @data.key?(method_name.to_s) || super
    end
  end
end
