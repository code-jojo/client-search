# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearchCli::Client do
  describe "#initialize" do
    context "with complete data" do
      let(:client_data) do
        {
          "id" => 1,
          "first_name" => "John",
          "last_name" => "Doe",
          "full_name" => "John Doe",
          "email" => "john@example.com"
        }
      end

      it "correctly initializes attributes" do
        client = described_class.new(client_data)
        
        expect(client.id).to eq(1)
        expect(client.first_name).to eq("John")
        expect(client.last_name).to eq("Doe")
        expect(client.full_name).to eq("John Doe")
        expect(client.email).to eq("john@example.com")
      end
    end

    context "with missing data" do
      let(:client_data) do
        { "id" => 2, "email" => "jane@example.com" }
      end

      it "handles missing name attributes" do
        client = described_class.new(client_data)
        
        expect(client.id).to eq(2)
        expect(client.email).to eq("jane@example.com")
        expect(client.full_name).to eq("")
        expect(client.first_name).to be_nil
        expect(client.last_name).to be_nil
      end
    end

    context "with only full_name" do
      let(:client_data) do
        { "id" => 3, "full_name" => "Jane Smith", "email" => "jane@example.com" }
      end

      it "derives first and last names from full_name" do
        client = described_class.new(client_data)
        
        expect(client.id).to eq(3)
        expect(client.full_name).to eq("Jane Smith")
        expect(client.first_name).to eq("Jane")
        expect(client.last_name).to eq("Smith")
      end
    end

    context "with only first_name and last_name" do
      let(:client_data) do
        { "id" => 4, "first_name" => "Bob", "last_name" => "Johnson", "email" => "bob@example.com" }
      end

      it "builds full_name from first and last names" do
        client = described_class.new(client_data)
        
        expect(client.id).to eq(4)
        expect(client.first_name).to eq("Bob")
        expect(client.last_name).to eq("Johnson")
        expect(client.full_name).to eq("Bob Johnson")
      end
    end

    context "with edge cases" do
      it "handles nil input data" do
        # Our implementation now handles nil data by defaulting to empty hash
        client = described_class.new(nil)
        expect(client.id).to be_nil
        expect(client.full_name).to eq("")
        expect(client.email).to be_nil
      end

      it "handles empty input data" do
        client = described_class.new({})
        
        expect(client.id).to be_nil
        expect(client.full_name).to eq("")
        expect(client.email).to be_nil
      end

      it "handles empty string values" do
        client = described_class.new({ "full_name" => "", "email" => "" })
        
        expect(client.full_name).to eq("")
        expect(client.email).to eq("")
        expect(client.first_name).to be_nil
        expect(client.last_name).to be_nil
      end
    end
  end

  describe "#name" do
    it "returns full_name when available" do
      client = described_class.new({ "full_name" => "John Doe" })
      expect(client.name).to eq("John Doe")
    end

    it "returns email when full_name is empty" do
      client = described_class.new({ "full_name" => "", "email" => "john@example.com" })
      expect(client.name).to eq("john@example.com")
    end

    it "returns email when full_name is nil" do
      client = described_class.new({ "full_name" => nil, "email" => "john@example.com" })
      expect(client.name).to eq("john@example.com")
    end

    it "returns empty string when both full_name and email are nil" do
      client = described_class.new({ "full_name" => nil, "email" => nil })
      expect(client.name).to eq("")
    end
  end

  describe "#first_name" do
    it "returns set first_name" do
      client = described_class.new({ "first_name" => "John", "full_name" => "John Doe" })
      expect(client.first_name).to eq("John")
    end

    it "extracts first_name from full_name when not set" do
      client = described_class.new({ "full_name" => "Jane Smith" })
      expect(client.first_name).to eq("Jane")
    end

    it "handles single-word full_name" do
      client = described_class.new({ "full_name" => "Madonna" })
      expect(client.first_name).to eq("Madonna")
    end

    it "handles nil full_name" do
      client = described_class.new({ "full_name" => nil })
      expect(client.first_name).to be_nil
    end

    it "handles empty string full_name" do
      client = described_class.new({ "full_name" => "" })
      expect(client.first_name).to be_nil
    end
  end

  describe "#last_name" do
    it "returns set last_name" do
      client = described_class.new({ "last_name" => "Doe", "full_name" => "John Doe" })
      expect(client.last_name).to eq("Doe")
    end

    it "extracts last_name from full_name when not set" do
      client = described_class.new({ "full_name" => "Jane Smith" })
      expect(client.last_name).to eq("Smith")
    end

    it "handles multi-word last names" do
      client = described_class.new({ "full_name" => "Juan de la Cruz" })
      expect(client.last_name).to eq("de la Cruz")
    end

    it "handles single-word full_name" do
      client = described_class.new({ "full_name" => "Madonna" })
      expect(client.last_name).to eq("")
    end

    it "handles nil full_name" do
      client = described_class.new({ "full_name" => nil })
      expect(client.last_name).to be_nil
    end

    it "handles empty string full_name" do
      client = described_class.new({ "full_name" => "" })
      expect(client.last_name).to be_nil
    end
  end

  describe "#to_h" do
    it "returns a hash with all client attributes" do
      client_data = {
        "id" => 1,
        "first_name" => "John",
        "last_name" => "Doe",
        "full_name" => "John Doe",
        "email" => "john@example.com"
      }
      
      client = described_class.new(client_data)
      client_hash = client.to_h
      
      expect(client_hash).to include(
        id: 1,
        first_name: "John",
        last_name: "Doe",
        full_name: "John Doe",
        email: "john@example.com"
      )
    end

    it "includes derived attributes" do
      client = described_class.new({ "id" => 1, "full_name" => "John Doe" })
      client_hash = client.to_h
      
      expect(client_hash).to include(
        id: 1,
        full_name: "John Doe",
        first_name: "John",
        last_name: "Doe"
      )
    end

    it "includes nil values for missing attributes" do
      client = described_class.new({ "id" => 1 })
      client_hash = client.to_h
      
      expect(client_hash).to include(
        id: 1,
        full_name: "",
        first_name: nil,
        last_name: nil,
        email: nil
      )
    end
  end
end 