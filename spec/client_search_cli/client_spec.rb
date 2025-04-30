# frozen_string_literal: true

require "spec_helper"

RSpec.describe ClientSearchCli::Client do
  describe "#initialize" do
    context "with complete data" do
      let(:client_data) do
        {
          "id" => 1,
          "full_name" => "John Doe",
          "email" => "john@example.com"
        }
      end

      it "correctly initializes attributes" do
        client = described_class.new(client_data)

        expect(client.id).to eq(1)
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
      end
    end

    context "with edge cases" do
      it "handles nil input data" do
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

  describe "#to_h" do
    it "returns a hash with all client attributes" do
      client_data = {
        "id" => 1,
        "full_name" => "John Doe",
        "email" => "john@example.com"
      }

      client = described_class.new(client_data)
      client_hash = client.to_h

      expect(client_hash).to include(
        id: 1,
        full_name: "John Doe",
        email: "john@example.com"
      )
    end

    it "includes nil values for missing attributes" do
      client = described_class.new({ "id" => 1 })
      client_hash = client.to_h

      expect(client_hash).to include(
        id: 1,
        full_name: "",
        email: nil
      )
    end
  end
end
