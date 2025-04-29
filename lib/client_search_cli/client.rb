# frozen_string_literal: true

module ClientSearchCli
  class Client
    attr_reader :id, :first_name, :last_name, :email, :phone, :address, :notes

    def initialize(data)
      @id = data["id"]
      @first_name = data["first_name"] || ""
      @last_name = data["last_name"] || ""
      @email = data["email"]
      @phone = data["phone"]
      @address = generate_address(data)
      @notes = data["notes"]
    end

    def name
      name = "#{first_name} #{last_name}".strip
      # If no name available, use email as display name
      name.empty? && email ? email : name
    end

    def to_h
      {
        id: id,
        name: name,
        first_name: first_name,
        last_name: last_name,
        email: email,
        phone: phone,
        address: address,
        notes: notes
      }
    end

    private

    def generate_address(data)
      address_parts = []
      address_parts << data["address"] if data["address"]
      address_parts << data["suburb"] if data["suburb"]
      address_parts << data["state"] if data["state"]
      address_parts << data["postcode"] if data["postcode"]
      
      address_parts.join(", ")
    end
  end
end 