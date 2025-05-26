# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when API authentication fails (401 Unauthorized)
  #
  # @example Handling authentication errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::AuthenticationError => e
  #     puts "Authentication failed: #{e.message}"
  #     puts "Please check your API key"
  #   end
  class AuthenticationError < Error
    # Initialize a new AuthenticationError
    #
    # @param message [String] the error message
    # @param context [Hash] additional context information
    def initialize(message = "Authentication failed", context: {})
      super(message, context: context, status_code: 401)
    end

    # Create an AuthenticationError for invalid API key
    #
    # @return [AuthenticationError] the authentication error
    def self.invalid_api_key
      new(
        "Invalid API key provided. Please check your API key and try again.",
        context: { error_type: "invalid_api_key" }
      )
    end

    # Create an AuthenticationError for missing API key
    #
    # @return [AuthenticationError] the authentication error
    def self.missing_api_key
      new(
        "API key is required. Please provide a valid API key.",
        context: { error_type: "missing_api_key" }
      )
    end

    # Create an AuthenticationError for expired API key
    #
    # @return [AuthenticationError] the authentication error
    def self.expired_api_key
      new(
        "API key has expired. Please generate a new API key.",
        context: { error_type: "expired_api_key" }
      )
    end
  end
end
