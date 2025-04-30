# frozen_string_literal: true

module ClientSearchCli
  class Client
    attr_reader :id, :full_name, :email, :first_name, :last_name

    # Initialize the client
    #
    # @param data [Hash] The data
    # @return [void]
    def initialize(data)
      data ||= {}
      @id = data["id"]
      @first_name = data["first_name"]
      @last_name = data["last_name"]
      @full_name = data["full_name"] || 
                   [@first_name, @last_name].compact.join(" ")
      @full_name = "" if @full_name.nil?
      @email = data["email"]
    end

    # Get the name of the client
    #
    # @return [String] The name
    def name
      name = "#{full_name}".strip
      name.empty? && email ? email : name
    end

    # Get the first name of the client
    #
    # @return [String] The first name
    def first_name
      return @first_name if @first_name
      
      # Only extract from full_name if it exists and isn't empty
      return nil if full_name.nil? || full_name.empty?
      
      @first_name ||= full_name.to_s.split.first
    end

    # Get the last name of the client
    #
    # @return [String] The last name
    def last_name
      return @last_name if @last_name
      
      # Only extract from full_name if it exists and isn't empty
      return nil if full_name.nil? || full_name.empty?
      
      name_parts = full_name.to_s.split
      return nil if name_parts.empty?
      return "" if name_parts.size == 1
      
      @last_name ||= name_parts[1..-1]&.join(" ")
    end

    # Get the hash of the client
    #
    # @return [Hash] The hash
    def to_h
      {
        id: id,
        full_name: full_name,
        first_name: first_name,
        last_name: last_name,
        email: email,
      }
    end
  end
end 