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
        expect(client.data).to eq(client_data)
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
        expect(client.data).to eq(client_data)
      end
    end

    context "with edge cases" do
      it "handles nil input data" do
        client = described_class.new(nil)
        expect(client.id).to be_nil
        expect(client.full_name).to eq("")
        expect(client.email).to be_nil
        expect(client.data).to eq({})
      end

      it "handles empty input data" do
        client = described_class.new({})

        expect(client.id).to be_nil
        expect(client.full_name).to eq("")
        expect(client.email).to be_nil
        expect(client.data).to eq({})
      end

      it "handles empty string values" do
        client = described_class.new({ "full_name" => "", "email" => "" })

        expect(client.full_name).to eq("")
        expect(client.email).to eq("")
      end
    end

    context "with custom fields" do
      let(:client_data) do
        {
          "id" => 1,
          "name" => "John Doe",
          "email" => "john@example.com",
          "phone" => "123-456-7890",
          "address" => "123 Main St",
          "custom_field" => "custom value"
        }
      end

      it "initializes with all custom fields" do
        client = described_class.new(client_data)

        expect(client.data).to eq(client_data.transform_keys(&:to_s))
        expect(client.data["phone"]).to eq("123-456-7890")
        expect(client.data["address"]).to eq("123 Main St")
        expect(client.data["custom_field"]).to eq("custom value")
      end

      it "uses name as full_name when full_name is not present" do
        client = described_class.new(client_data)
        expect(client.full_name).to eq("John Doe")
      end

      it "correctly handles symbol keys" do
        data_with_symbols = {
          id: 1,
          name: "John Doe",
          email: "john@example.com"
        }

        client = described_class.new(data_with_symbols)
        expect(client.id).to eq(1)
        expect(client.full_name).to eq("John Doe")
        expect(client.email).to eq("john@example.com")
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
    it "returns the entire data hash" do
      client_data = {
        "id" => 1,
        "full_name" => "John Doe",
        "email" => "john@example.com",
        "custom_field" => "custom value"
      }

      client = described_class.new(client_data)
      client_hash = client.to_h

      expect(client_hash).to eq(client_data)
    end
  end

  describe "dynamic field access" do
    let(:client_data) do
      {
        "id" => 1,
        "full_name" => "John Doe",
        "email" => "john@example.com",
        "phone" => "123-456-7890",
        "custom_field" => "custom value"
      }
    end

    subject(:client) { described_class.new(client_data) }

    it "allows access to standard fields through methods" do
      expect(client.id).to eq(1)
      expect(client.full_name).to eq("John Doe")
      expect(client.email).to eq("john@example.com")
    end

    it "allows access to custom fields through method_missing" do
      expect(client.phone).to eq("123-456-7890")
      expect(client.custom_field).to eq("custom value")
    end

    it "raises NoMethodError for undefined fields" do
      expect { client.nonexistent_field }.to raise_error(NoMethodError)
    end

    it "responds correctly to respond_to?" do
      expect(client.respond_to?(:id)).to be true
      expect(client.respond_to?(:full_name)).to be true
      expect(client.respond_to?(:email)).to be true
      expect(client.respond_to?(:phone)).to be true
      expect(client.respond_to?(:custom_field)).to be true
      expect(client.respond_to?(:nonexistent_field)).to be false
    end
  end
end
