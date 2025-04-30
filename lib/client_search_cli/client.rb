# frozen_string_literal: true

module ClientSearchCli
  class Client
    attr_reader :id, :full_name, :email

    # Initialize the client
    #
    # @param data [Hash] The data
    # @return [void]
    def initialize(data)
      data ||= {}
      @id = data["id"]
      @full_name = data["full_name"] || ""
      @email = data["email"]
    end

    # Get the name of the client
    #
    # @return [String] The name
    def name
      name = "#{full_name}".strip
      name.empty? && email ? email : name
    end

    # Get the hash of the client
    #
    # @return [Hash] The hash
    def to_h
      {
        id: id,
        full_name: full_name,
        email: email,
      }
    end
  end
end 