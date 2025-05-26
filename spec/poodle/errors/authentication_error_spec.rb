# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::AuthenticationError do
  describe "#initialize" do
    it "creates error with default message" do
      error = described_class.new

      expect(error.message).to eq("Authentication failed")
      expect(error.to_s).to include("Authentication failed")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq({})
    end

    it "creates error with custom message" do
      error = described_class.new("Custom auth error")

      expect(error.message).to eq("Custom auth error")
      expect(error.to_s).to include("Custom auth error")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq({})
    end

    it "creates error with context" do
      context = { user_id: "123", request_id: "abc" }
      error = described_class.new("Auth failed", context: context)

      expect(error.message).to eq("Auth failed")
      expect(error.to_s).to include("Auth failed")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.to_s).to include("Context:")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq(context)
    end
  end

  describe ".invalid_api_key" do
    it "creates error for invalid API key" do
      error = described_class.invalid_api_key

      expect(error.message).to eq("Invalid API key provided. Please check your API key and try again.")
      expect(error.to_s).to include("Invalid API key provided")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.to_s).to include("Context:")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq({ error_type: "invalid_api_key" })
    end
  end

  describe ".missing_api_key" do
    it "creates error for missing API key" do
      error = described_class.missing_api_key

      expect(error.message).to eq("API key is required. Please provide a valid API key.")
      expect(error.to_s).to include("API key is required")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.to_s).to include("Context:")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq({ error_type: "missing_api_key" })
    end
  end

  describe ".expired_api_key" do
    it "creates error for expired API key" do
      error = described_class.expired_api_key

      expect(error.message).to eq("API key has expired. Please generate a new API key.")
      expect(error.to_s).to include("API key has expired")
      expect(error.to_s).to include("(Status: 401)")
      expect(error.to_s).to include("Context:")
      expect(error.status_code).to eq(401)
      expect(error.context).to eq({ error_type: "expired_api_key" })
    end
  end

  describe "inheritance" do
    it "inherits from Poodle::Error" do
      error = described_class.new
      expect(error).to be_a(Poodle::Error)
    end

    it "inherits from StandardError" do
      error = described_class.new
      expect(error).to be_a(StandardError)
    end

    it "can be rescued as Poodle::Error" do
      expect do
        raise described_class, "Test auth error"
      rescue Poodle::Error => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test auth error")
        expect(e.to_s).to eq("Test auth error (Status: 401)")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end

    it "can be rescued as AuthenticationError" do
      expect do
        raise described_class, "Test auth error"
      rescue Poodle::AuthenticationError => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test auth error")
        expect(e.to_s).to eq("Test auth error (Status: 401)")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end

  describe "#to_s" do
    it "includes status code in string representation" do
      error = described_class.new("Authentication failed")

      expect(error.to_s).to eq("Authentication failed (Status: 401)")
    end

    it "includes context in string representation" do
      context = { error_type: "invalid_api_key" }
      error = described_class.new("Invalid API key", context: context)

      result = error.to_s
      expect(result).to include("Invalid API key")
      expect(result).to include("(Status: 401)")
      expect(result).to include("Context:")
      expect(result).to include("invalid_api_key")
    end
  end
end
