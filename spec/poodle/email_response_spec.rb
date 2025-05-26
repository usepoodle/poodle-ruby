# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::EmailResponse do
  describe "#initialize" do
    it "creates a successful response" do
      response = described_class.new(
        success: true,
        message: "Email queued successfully",
        data: { id: "123", status: "queued" }
      )

      expect(response.success).to be true
      expect(response.message).to eq("Email queued successfully")
      expect(response.data).to eq({ id: "123", status: "queued" })
    end

    it "creates a failed response" do
      response = described_class.new(
        success: false,
        message: "Email failed to queue",
        data: { error: "Invalid recipient" }
      )

      expect(response.success).to be false
      expect(response.message).to eq("Email failed to queue")
      expect(response.data).to eq({ error: "Invalid recipient" })
    end

    it "creates response with default empty data" do
      response = described_class.new(
        success: true,
        message: "Email queued"
      )

      expect(response.success).to be true
      expect(response.message).to eq("Email queued")
      expect(response.data).to eq({})
    end

    it "freezes the object after creation" do
      response = described_class.new(
        success: true,
        message: "Email queued"
      )

      expect(response).to be_frozen
    end
  end

  describe ".from_api_response" do
    it "creates response from API data with symbol keys" do
      api_data = {
        success: true,
        message: "Email queued successfully",
        id: "123",
        status: "queued"
      }

      response = described_class.from_api_response(api_data)

      expect(response.success).to be true
      expect(response.message).to eq("Email queued successfully")
      expect(response.data).to eq(api_data)
    end

    it "creates response from API data with string keys" do
      api_data = {
        "success" => true,
        "message" => "Email queued successfully",
        "id" => "123",
        "status" => "queued"
      }

      response = described_class.from_api_response(api_data)

      expect(response.success).to be true
      expect(response.message).to eq("Email queued successfully")
      expect(response.data).to eq(api_data)
    end

    it "handles missing success field" do
      api_data = {
        "message" => "Email queued successfully",
        "id" => "123"
      }

      response = described_class.from_api_response(api_data)

      expect(response.success).to be false
      expect(response.message).to eq("Email queued successfully")
      expect(response.data).to eq(api_data)
    end

    it "handles missing message field" do
      api_data = {
        "success" => true,
        "id" => "123"
      }

      response = described_class.from_api_response(api_data)

      expect(response.success).to be true
      expect(response.message).to eq("")
      expect(response.data).to eq(api_data)
    end

    it "prefers symbol keys over string keys" do
      api_data = {
        success: true,
        "success" => false,
        message: "Symbol message",
        "message" => "String message"
      }

      response = described_class.from_api_response(api_data)

      expect(response.success).to be true
      expect(response.message).to eq("Symbol message")
    end
  end

  describe "#success?" do
    it "returns true for successful response" do
      response = described_class.new(success: true, message: "Success")
      expect(response.success?).to be true
    end

    it "returns false for failed response" do
      response = described_class.new(success: false, message: "Failed")
      expect(response.success?).to be false
    end
  end

  describe "#failed?" do
    it "returns false for successful response" do
      response = described_class.new(success: true, message: "Success")
      expect(response.failed?).to be false
    end

    it "returns true for failed response" do
      response = described_class.new(success: false, message: "Failed")
      expect(response.failed?).to be true
    end
  end

  describe "#to_h" do
    it "converts response to hash" do
      response = described_class.new(
        success: true,
        message: "Email queued",
        data: { id: "123", status: "queued" }
      )

      hash = response.to_h

      expect(hash).to eq({
                           success: true,
                           message: "Email queued",
                           data: { id: "123", status: "queued" }
                         })
    end

    it "converts response with empty data to hash" do
      response = described_class.new(
        success: false,
        message: "Failed"
      )

      hash = response.to_h

      expect(hash).to eq({
                           success: false,
                           message: "Failed",
                           data: {}
                         })
    end
  end

  describe "#to_json" do
    it "converts response to JSON string" do
      response = described_class.new(
        success: true,
        message: "Email queued",
        data: { id: "123", status: "queued" }
      )

      json = response.to_json
      parsed = JSON.parse(json)

      expect(parsed).to eq({
                             "success" => true,
                             "message" => "Email queued",
                             "data" => { "id" => "123", "status" => "queued" }
                           })
    end

    it "passes through JSON options" do
      response = described_class.new(
        success: true,
        message: "Email queued",
        data: { id: "123" }
      )

      # Test that options are passed through (pretty printing)
      json = response.to_json(indent: "  ", space: " ", object_nl: "\n", array_nl: "\n")
      expect(json).to include("\n")
    end
  end

  describe "#to_s" do
    it "returns formatted string for successful response" do
      response = described_class.new(
        success: true,
        message: "Email queued successfully"
      )

      expect(response.to_s).to eq("EmailResponse[SUCCESS]: Email queued successfully")
    end

    it "returns formatted string for failed response" do
      response = described_class.new(
        success: false,
        message: "Email failed to queue"
      )

      expect(response.to_s).to eq("EmailResponse[FAILED]: Email failed to queue")
    end

    it "handles empty message" do
      response = described_class.new(
        success: true,
        message: ""
      )

      expect(response.to_s).to eq("EmailResponse[SUCCESS]: ")
    end
  end

  describe "#inspect" do
    it "returns detailed string representation" do
      response = described_class.new(
        success: true,
        message: "Email queued",
        data: { id: "123" }
      )

      inspect_string = response.inspect

      expect(inspect_string).to include("Poodle::EmailResponse")
      expect(inspect_string).to include("success=true")
      expect(inspect_string).to include('message="Email queued"')
      expect(inspect_string).to include('data={:id=>"123"}')
      expect(inspect_string).to match(/:0x[0-9a-f]+/) # object_id in hex
    end

    it "handles complex data structures" do
      response = described_class.new(
        success: false,
        message: "Validation failed",
        data: {
          errors: ["Invalid email", "Missing subject"],
          code: 400
        }
      )

      inspect_string = response.inspect

      expect(inspect_string).to include("success=false")
      expect(inspect_string).to include('message="Validation failed"')
      expect(inspect_string).to include("errors")
      expect(inspect_string).to include("Invalid email")
    end
  end
end
