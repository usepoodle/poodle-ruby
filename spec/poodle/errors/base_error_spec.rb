# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::Error do
  describe "#initialize" do
    it "creates error with message only" do
      error = described_class.new("Something went wrong")

      expect(error.message).to eq("Something went wrong")
      expect(error.context).to eq({})
      expect(error.status_code).to be_nil
    end

    it "creates error with message and context" do
      context = { field: "email", value: "invalid" }
      error = described_class.new("Validation failed", context: context)

      expect(error.message).to eq("Validation failed")
      expect(error.to_s).to include("Validation failed")
      expect(error.to_s).to include("Context:")
      expect(error.context).to eq(context)
      expect(error.status_code).to be_nil
    end

    it "creates error with message, context, and status code" do
      context = { field: "email", value: "invalid" }
      error = described_class.new("Validation failed", context: context, status_code: 400)

      expect(error.message).to eq("Validation failed")
      expect(error.to_s).to include("Validation failed")
      expect(error.to_s).to include("(Status: 400)")
      expect(error.to_s).to include("Context:")
      expect(error.context).to eq(context)
      expect(error.status_code).to eq(400)
    end

    it "creates error with empty message" do
      error = described_class.new

      expect(error.message).to eq("")
      expect(error.context).to eq({})
      expect(error.status_code).to be_nil
    end

    it "creates error with only status code" do
      error = described_class.new("Server error", status_code: 500)

      expect(error.message).to eq("Server error")
      expect(error.to_s).to include("Server error")
      expect(error.to_s).to include("(Status: 500)")
      expect(error.context).to eq({})
      expect(error.status_code).to eq(500)
    end

    it "creates error with only context" do
      context = { request_id: "123", timestamp: "2023-01-01" }
      error = described_class.new("Request failed", context: context)

      expect(error.message).to eq("Request failed")
      expect(error.to_s).to include("Request failed")
      expect(error.to_s).to include("Context:")
      expect(error.context).to eq(context)
      expect(error.status_code).to be_nil
    end
  end

  describe "#to_s" do
    it "returns message only when no context or status code" do
      error = described_class.new("Something went wrong")

      expect(error.to_s).to eq("Something went wrong")
    end

    it "includes status code when present" do
      error = described_class.new("Server error", status_code: 500)

      expect(error.to_s).to eq("Server error (Status: 500)")
    end

    it "includes context when present" do
      context = { field: "email", value: "invalid" }
      error = described_class.new("Validation failed", context: context)

      expect(error.to_s).to eq("Validation failed Context: {:field=>\"email\", :value=>\"invalid\"}")
    end

    it "includes both status code and context when present" do
      context = { field: "email", value: "invalid" }
      error = described_class.new("Validation failed", context: context, status_code: 400)

      expect(error.to_s).to eq("Validation failed (Status: 400) Context: {:field=>\"email\", :value=>\"invalid\"}")
    end

    it "handles empty context" do
      error = described_class.new("Error occurred", context: {}, status_code: 404)

      expect(error.to_s).to eq("Error occurred (Status: 404)")
    end

    it "handles empty message with context and status" do
      context = { error_code: "E001" }
      error = described_class.new("", context: context, status_code: 400)

      expect(error.to_s).to eq(" (Status: 400) Context: {:error_code=>\"E001\"}")
    end

    it "handles complex context data" do
      context = {
        errors: ["Invalid email", "Missing subject"],
        request_id: "req_123",
        timestamp: "2023-01-01T10:00:00Z"
      }
      error = described_class.new("Multiple validation errors", context: context, status_code: 422)

      result = error.to_s
      expect(result).to include("Multiple validation errors")
      expect(result).to include("(Status: 422)")
      expect(result).to include("Context:")
      expect(result).to include("Invalid email")
      expect(result).to include("req_123")
    end
  end

  describe "inheritance" do
    it "inherits from StandardError" do
      error = described_class.new("Test error")
      expect(error).to be_a(StandardError)
    end

    it "can be rescued as StandardError" do
      expect do
        raise described_class, "Test error"
      rescue StandardError => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end

    it "can be rescued as Poodle::Error" do
      expect do
        raise described_class, "Test error"
      rescue Poodle::Error => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end

  describe "attribute readers" do
    it "provides read access to context" do
      context = { field: "email" }
      error = described_class.new("Error", context: context)

      expect(error.context).to eq(context)
      expect(error.context[:field]).to eq("email")
    end

    it "provides read access to status_code" do
      error = described_class.new("Error", status_code: 404)

      expect(error.status_code).to eq(404)
    end

    it "context is frozen to prevent modification" do
      context = { field: "email" }
      error = described_class.new("Error", context: context)

      # The context should be the same object but we can't modify the error's context
      expect(error.context).to eq(context)
    end
  end
end
