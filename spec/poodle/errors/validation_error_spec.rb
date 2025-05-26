# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::ValidationError do
  describe "#initialize" do
    it "creates error with default message and empty errors" do
      error = described_class.new

      expect(error.message).to eq("Validation failed")
      expect(error.errors).to eq({})
      expect(error.status_code).to eq(400)
      expect(error.context[:errors]).to eq({})
    end

    it "creates error with custom message" do
      error = described_class.new("Custom validation message")

      expect(error.message).to eq("Custom validation message")
      expect(error.errors).to eq({})
      expect(error.status_code).to eq(400)
    end

    it "creates error with errors hash" do
      errors = { email: ["Invalid format"], name: ["Required"] }
      error = described_class.new("Validation failed", errors: errors)

      expect(error.message).to eq("Validation failed")
      expect(error.errors).to eq(errors)
      expect(error.status_code).to eq(400)
      expect(error.context[:errors]).to eq(errors)
    end

    it "creates error with custom status code" do
      error = described_class.new("Validation failed", status_code: 422)

      expect(error.message).to eq("Validation failed")
      expect(error.status_code).to eq(422)
    end

    it "creates error with context" do
      context = { request_id: "123" }
      errors = { email: ["Invalid"] }
      error = described_class.new("Validation failed", errors: errors, context: context)

      expect(error.context[:request_id]).to eq("123")
      expect(error.context[:errors]).to eq(errors)
    end

    it "merges errors into context" do
      context = { request_id: "123", other: "data" }
      errors = { email: ["Invalid"] }
      error = described_class.new("Validation failed", errors: errors, context: context)

      expect(error.context).to include(request_id: "123", other: "data", errors: errors)
    end
  end

  describe ".invalid_email" do
    it "creates error for invalid email with default field" do
      error = described_class.invalid_email("invalid-email")

      expect(error.message).to eq("Invalid email address provided")
      expect(error.errors).to eq({
                                   "email" => ["'invalid-email' is not a valid email address"]
                                 })
      expect(error.status_code).to eq(400)
    end

    it "creates error for invalid email with custom field" do
      error = described_class.invalid_email("bad@email", field: "sender")

      expect(error.message).to eq("Invalid email address provided")
      expect(error.errors).to eq({
                                   "sender" => ["'bad@email' is not a valid email address"]
                                 })
    end

    it "handles empty email" do
      error = described_class.invalid_email("")

      expect(error.message).to eq("Invalid email address provided")
      expect(error.errors).to eq({
                                   "email" => ["'' is not a valid email address"]
                                 })
    end

    it "handles nil email" do
      error = described_class.invalid_email(nil)

      expect(error.message).to eq("Invalid email address provided")
      expect(error.errors).to eq({
                                   "email" => ["'' is not a valid email address"]
                                 })
    end
  end

  describe ".missing_field" do
    it "creates error for missing field" do
      error = described_class.missing_field("email")

      expect(error.message).to eq("Missing required field: email")
      expect(error.errors).to eq({
                                   "email" => ["The email field is required"]
                                 })
      expect(error.status_code).to eq(400)
    end

    it "creates error for different missing fields" do
      error = described_class.missing_field("subject")

      expect(error.message).to eq("Missing required field: subject")
      expect(error.errors).to eq({
                                   "subject" => ["The subject field is required"]
                                 })
    end

    it "handles field names with special characters" do
      error = described_class.missing_field("api_key")

      expect(error.message).to eq("Missing required field: api_key")
      expect(error.errors).to eq({
                                   "api_key" => ["The api_key field is required"]
                                 })
    end
  end

  describe ".invalid_content" do
    it "creates error for invalid content" do
      error = described_class.invalid_content

      expect(error.message).to eq("Email must contain either HTML content, text content, or both")
      expect(error.errors).to eq({
                                   content: ["At least one content type (html or text) is required"]
                                 })
      expect(error.status_code).to eq(400)
    end
  end

  describe ".content_too_large" do
    it "creates error for content too large" do
      error = described_class.content_too_large("html", 1024)

      expect(error.message).to eq("Content size exceeds maximum allowed size of 1024 bytes")
      expect(error.errors).to eq({
                                   "html" => ["Content size exceeds maximum allowed size of 1024 bytes"]
                                 })
      expect(error.status_code).to eq(400)
    end

    it "creates error for different field and size" do
      error = described_class.content_too_large("text", 2048)

      expect(error.message).to eq("Content size exceeds maximum allowed size of 2048 bytes")
      expect(error.errors).to eq({
                                   "text" => ["Content size exceeds maximum allowed size of 2048 bytes"]
                                 })
    end

    it "handles zero max size" do
      error = described_class.content_too_large("attachment", 0)

      expect(error.message).to eq("Content size exceeds maximum allowed size of 0 bytes")
      expect(error.errors).to eq({
                                   "attachment" => ["Content size exceeds maximum allowed size of 0 bytes"]
                                 })
    end
  end

  describe ".invalid_field_value" do
    it "creates error for invalid field value without reason" do
      error = described_class.invalid_field_value("priority", "urgent")

      expect(error.message).to eq("Invalid value for field 'priority': urgent")
      expect(error.errors).to eq({
                                   "priority" => ["Invalid value for field 'priority': urgent"]
                                 })
      expect(error.status_code).to eq(400)
    end

    it "creates error for invalid field value with reason" do
      error = described_class.invalid_field_value("priority", "urgent", "Must be low, medium, or high")

      expect(error.message).to eq("Invalid value for field 'priority': urgent. Must be low, medium, or high")
      expect(error.errors).to eq({
                                   "priority" => ["Invalid value for field 'priority': urgent. Must be low, medium, or high"]
                                 })
    end

    it "handles empty reason" do
      error = described_class.invalid_field_value("status", "invalid", "")

      expect(error.message).to eq("Invalid value for field 'status': invalid")
      expect(error.errors).to eq({
                                   "status" => ["Invalid value for field 'status': invalid"]
                                 })
    end

    it "handles nil value" do
      error = described_class.invalid_field_value("type", nil, "Cannot be nil")

      expect(error.message).to eq("Invalid value for field 'type': . Cannot be nil")
      expect(error.errors).to eq({
                                   "type" => ["Invalid value for field 'type': . Cannot be nil"]
                                 })
    end

    it "handles complex field names" do
      error = described_class.invalid_field_value("user[email]", "bad@email", "Invalid format")

      expect(error.message).to eq("Invalid value for field 'user[email]': bad@email. Invalid format")
      expect(error.errors).to eq({
                                   "user[email]" => ["Invalid value for field 'user[email]': bad@email. Invalid format"]
                                 })
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
        raise described_class, "Test validation error"
      rescue Poodle::Error => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test validation error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end

    it "can be rescued as ValidationError" do
      expect do
        raise described_class, "Test validation error"
      rescue Poodle::ValidationError => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test validation error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end

  describe "#errors attribute" do
    it "provides read access to errors" do
      errors = { email: ["Invalid"], name: ["Required"] }
      error = described_class.new("Validation failed", errors: errors)

      expect(error.errors).to eq(errors)
      expect(error.errors[:email]).to eq(["Invalid"])
      expect(error.errors[:name]).to eq(["Required"])
    end

    it "returns empty hash when no errors provided" do
      error = described_class.new("Validation failed")

      expect(error.errors).to eq({})
      expect(error.errors[:nonexistent]).to be_nil
    end
  end

  describe "#to_s" do
    it "includes errors in string representation" do
      errors = { email: ["Invalid format"] }
      error = described_class.new("Validation failed", errors: errors)

      result = error.to_s
      expect(result).to include("Validation failed")
      expect(result).to include("(Status: 400)")
      expect(result).to include("Context:")
      expect(result).to include("Invalid format")
    end

    it "handles multiple errors" do
      errors = {
        email: ["Invalid format", "Already taken"],
        name: ["Required", "Too short"]
      }
      error = described_class.new("Multiple validation errors", errors: errors)

      result = error.to_s
      expect(result).to include("Multiple validation errors")
      expect(result).to include("Invalid format")
      expect(result).to include("Already taken")
      expect(result).to include("Required")
      expect(result).to include("Too short")
    end
  end
end
