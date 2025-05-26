# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when server errors occur (5xx status codes)
  #
  # @example Handling server errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::ServerError => e
  #     puts "Server error: #{e.message}"
  #     puts "Status code: #{e.status_code}"
  #   end
  class ServerError < Error
    # Initialize a new ServerError
    #
    # @param message [String] the error message
    # @param context [Hash] additional context information
    # @param status_code [Integer] HTTP status code (5xx)
    def initialize(message = "Server error occurred", context: {}, status_code: 500)
      super(message, context: context.merge(error_type: "server_error"), status_code: status_code)
    end

    # Create a ServerError for internal server error
    #
    # @param message [String] the error message
    # @return [ServerError] the server error
    def self.internal_server_error(message = "Internal server error")
      new(message, status_code: 500)
    end

    # Create a ServerError for bad gateway
    #
    # @param message [String] the error message
    # @return [ServerError] the server error
    def self.bad_gateway(message = "Bad gateway")
      new(message, status_code: 502)
    end

    # Create a ServerError for service unavailable
    #
    # @param message [String] the error message
    # @return [ServerError] the server error
    def self.service_unavailable(message = "Service unavailable")
      new(message, status_code: 503)
    end

    # Create a ServerError for gateway timeout
    #
    # @param message [String] the error message
    # @return [ServerError] the server error
    def self.gateway_timeout(message = "Gateway timeout")
      new(message, status_code: 504)
    end
  end
end
