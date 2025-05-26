# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when network or HTTP errors occur
  #
  # @example Handling network errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::NetworkError => e
  #     puts "Network error: #{e.message}"
  #     puts "Original error: #{e.original_error}" if e.original_error
  #   end
  class NetworkError < Error
    # @return [Exception, nil] the original exception that caused this error
    attr_reader :original_error

    # Initialize a new NetworkError
    #
    # @param message [String] the error message
    # @param original_error [Exception, nil] the original exception
    # @param context [Hash] additional context information
    # @param status_code [Integer, nil] HTTP status code
    def initialize(message = "Network error occurred", original_error: nil, context: {}, status_code: nil)
      @original_error = original_error
      super(message, context: context, status_code: status_code)
    end

    # Create a NetworkError for connection timeout
    #
    # @param timeout [Integer] the timeout duration
    # @return [NetworkError] the network error
    def self.connection_timeout(timeout)
      new(
        "Connection timeout after #{timeout} seconds",
        context: { timeout: timeout, error_type: "connection_timeout" },
        status_code: 408
      )
    end

    # Create a NetworkError for connection failure
    #
    # @param url [String] the URL that failed to connect
    # @param original_error [Exception, nil] the original exception
    # @return [NetworkError] the network error
    def self.connection_failed(url, original_error: nil)
      new(
        "Failed to connect to #{url}",
        original_error: original_error,
        context: { url: url, error_type: "connection_failed" }
      )
    end

    # Create a NetworkError for DNS resolution failure
    #
    # @param host [String] the host that failed to resolve
    # @return [NetworkError] the network error
    def self.dns_resolution_failed(host)
      new(
        "DNS resolution failed for host: #{host}",
        context: { host: host, error_type: "dns_resolution_failed" }
      )
    end

    # Create a NetworkError for SSL/TLS errors
    #
    # @param message [String] the SSL error message
    # @return [NetworkError] the network error
    def self.ssl_error(message)
      new(
        "SSL/TLS error: #{message}",
        context: { error_type: "ssl_error" }
      )
    end

    # Create a NetworkError for HTTP errors
    #
    # @param status_code [Integer] the HTTP status code
    # @param message [String] the error message
    # @return [NetworkError] the network error
    def self.http_error(status_code, message = "")
      default_message = "HTTP error occurred with status code: #{status_code}"
      final_message = message.empty? ? default_message : message

      new(
        final_message,
        context: { error_type: "http_error" },
        status_code: status_code
      )
    end

    # Create a NetworkError for malformed response
    #
    # @param response [String] the malformed response
    # @return [NetworkError] the network error
    def self.malformed_response(response = "")
      new(
        "Received malformed response from server",
        context: { response: response, error_type: "malformed_response" }
      )
    end
  end
end
