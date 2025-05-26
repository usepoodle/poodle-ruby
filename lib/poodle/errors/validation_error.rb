# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when request validation fails (400 Bad Request, 422 Unprocessable Entity)
  #
  # @example Handling validation errors
  #   begin
  #     client.send_email(invalid_email)
  #   rescue Poodle::ValidationError => e
  #     puts "Validation failed: #{e.message}"
  #     e.errors.each do |field, messages|
  #       puts "#{field}: #{messages.join(', ')}"
  #     end
  #   end
  class ValidationError < Error
    # @return [Hash] field-specific validation errors
    attr_reader :errors

    # Initialize a new ValidationError
    #
    # @param message [String] the error message
    # @param errors [Hash] field-specific validation errors
    # @param context [Hash] additional context information
    # @param status_code [Integer] HTTP status code (400 or 422)
    def initialize(message = "Validation failed", errors: {}, context: {}, status_code: 400)
      @errors = errors
      super(message, context: context.merge(errors: errors), status_code: status_code)
    end

    # Create a ValidationError for invalid email address
    #
    # @param email [String] the invalid email address
    # @param field [String] the field name (default: "email")
    # @return [ValidationError] the validation error
    def self.invalid_email(email, field: "email")
      new(
        "Invalid email address provided",
        errors: { field => ["'#{email}' is not a valid email address"] }
      )
    end

    # Create a ValidationError for missing required field
    #
    # @param field [String] the missing field name
    # @return [ValidationError] the validation error
    def self.missing_field(field)
      new(
        "Missing required field: #{field}",
        errors: { field => ["The #{field} field is required"] }
      )
    end

    # Create a ValidationError for invalid content
    #
    # @return [ValidationError] the validation error
    def self.invalid_content
      new(
        "Email must contain either HTML content, text content, or both",
        errors: { content: ["At least one content type (html or text) is required"] }
      )
    end

    # Create a ValidationError for content too large
    #
    # @param field [String] the field name
    # @param max_size [Integer] the maximum allowed size
    # @return [ValidationError] the validation error
    def self.content_too_large(field, max_size)
      new(
        "Content size exceeds maximum allowed size of #{max_size} bytes",
        errors: { field => ["Content size exceeds maximum allowed size of #{max_size} bytes"] }
      )
    end

    # Create a ValidationError for invalid field value
    #
    # @param field [String] the field name
    # @param value [String] the invalid value
    # @param reason [String] the reason why it's invalid
    # @return [ValidationError] the validation error
    def self.invalid_field_value(field, value, reason = "")
      message = "Invalid value for field '#{field}': #{value}"
      message += ". #{reason}" unless reason.empty?

      new(
        message,
        errors: { field => [message] }
      )
    end
  end
end
