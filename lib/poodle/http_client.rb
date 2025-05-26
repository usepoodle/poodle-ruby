# frozen_string_literal: true

require "faraday"
require "json"
require_relative "configuration"
require_relative "errors/authentication_error"
require_relative "errors/payment_error"
require_relative "errors/forbidden_error"
require_relative "errors/rate_limit_error"
require_relative "errors/validation_error"
require_relative "errors/network_error"
require_relative "errors/server_error"

module Poodle
  # HTTP client wrapper for Poodle API communication
  #
  # @example Basic usage
  #   config = Poodle::Configuration.new(api_key: "your_api_key")
  #   client = Poodle::HttpClient.new(config)
  #   response = client.post("api/v1/send-email", email_data)
  class HttpClient
    # @return [Configuration] the configuration object
    attr_reader :config

    # Initialize a new HttpClient
    #
    # @param config [Configuration] the configuration object
    def initialize(config)
      @config = config
      @connection = build_connection
    end

    # Send a POST request
    #
    # @param endpoint [String] the API endpoint
    # @param data [Hash] the request data
    # @param headers [Hash] additional headers
    # @return [Hash] the parsed response data
    # @raise [Poodle::Error] if the request fails
    def post(endpoint, data = {}, headers = {})
      request(:post, endpoint, data, headers)
    end

    # Send a GET request
    #
    # @param endpoint [String] the API endpoint
    # @param params [Hash] query parameters
    # @param headers [Hash] additional headers
    # @return [Hash] the parsed response data
    # @raise [Poodle::Error] if the request fails
    def get(endpoint, params = {}, headers = {})
      request(:get, endpoint, params, headers)
    end

    private

    # Send an HTTP request
    #
    # @param method [Symbol] the HTTP method
    # @param endpoint [String] the API endpoint
    # @param data [Hash] the request data or query parameters
    # @param headers [Hash] additional headers
    # @return [Hash] the parsed response data
    # @raise [Poodle::Error] if the request fails
    def request(method, endpoint, data = {}, headers = {})
      url = @config.url_for(endpoint)

      log_request(method, url, data) if @config.debug?

      response = perform_request(method, url, data, headers)

      log_response(response) if @config.debug?

      handle_response(response)
    rescue Faraday::TimeoutError => e
      puts "TimeoutError: #{e.message}"
      raise NetworkError.connection_timeout(@config.timeout)
    rescue Faraday::ConnectionFailed => e
      handle_connection_failed_error(e)
    rescue Faraday::Error => e
      raise NetworkError.connection_failed(@config.base_url, original_error: e)
    end

    # Perform the actual HTTP request
    #
    # @param method [Symbol] the HTTP method
    # @param url [String] the request URL
    # @param data [Hash] the request data
    # @param headers [Hash] additional headers
    # @return [Faraday::Response] the HTTP response
    def perform_request(method, url, data, headers)
      case method
      when :post
        @connection.post(url) do |req|
          req.headers.update(headers)
          req.body = data.to_json
        end
      when :get
        @connection.get(url) do |req|
          req.headers.update(headers)
          req.params = data
        end
      else
        raise ArgumentError, "Unsupported HTTP method: #{method}"
      end
    end

    # Handle connection failed errors
    #
    # @param error [Faraday::ConnectionFailed] the connection error
    # @raise [NetworkError] the appropriate network error
    def handle_connection_failed_error(error)
      if error.message.include?("SSL") || error.message.include?("certificate")
        raise NetworkError.ssl_error(error.message)
      elsif error.message.include?("resolve") || error.message.include?("DNS")
        host = URI.parse(@config.base_url).host
        raise NetworkError.dns_resolution_failed(host)
      else
        raise NetworkError.connection_failed(@config.base_url, original_error: error)
      end
    end

    # Build the Faraday connection
    #
    # @return [Faraday::Connection] the configured connection
    def build_connection
      Faraday.new do |conn|
        configure_connection_middleware(conn)
        configure_connection_timeouts(conn)
        configure_connection_headers(conn)
        configure_custom_options(conn)
      end
    end

    # Configure connection middleware
    #
    # @param conn [Faraday::Connection] the connection
    def configure_connection_middleware(conn)
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end

    # Configure connection timeouts
    #
    # @param conn [Faraday::Connection] the connection
    def configure_connection_timeouts(conn)
      conn.options.timeout = @config.timeout
      conn.options.open_timeout = @config.connect_timeout
    end

    # Configure connection headers
    #
    # @param conn [Faraday::Connection] the connection
    def configure_connection_headers(conn)
      conn.headers["Authorization"] = "Bearer #{@config.api_key}"
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Accept"] = "application/json"
      conn.headers["User-Agent"] = @config.user_agent
    end

    # Configure custom HTTP options
    #
    # @param conn [Faraday::Connection] the connection
    def configure_custom_options(conn)
      @config.http_options.each do |key, value|
        conn.options[key] = value
      end
    end

    # Handle HTTP response
    #
    # @param response [Faraday::Response] the HTTP response
    # @return [Hash] the parsed response data
    # @raise [Poodle::Error] if the response indicates an error
    def handle_response(response)
      return response.body || {} if success_response?(response)

      handle_error_response(response)
    end

    # Check if response is successful
    #
    # @param response [Faraday::Response] the HTTP response
    # @return [Boolean] true if successful
    def success_response?(response)
      (200..299).cover?(response.status)
    end

    # Handle error responses
    #
    # @param response [Faraday::Response] the HTTP response
    # @raise [Poodle::Error] the appropriate error
    def handle_error_response(response)
      case response.status
      when 400
        handle_validation_error(response)
      when 401
        raise AuthenticationError.invalid_api_key
      when 402
        handle_payment_error(response)
      when 403
        handle_forbidden_error(response)
      when 422
        handle_validation_error(response, status_code: 422)
      when 429
        raise RateLimitError.from_headers(response.headers)
      when 500..599
        handle_server_error(response)
      else
        raise NetworkError.http_error(response.status, extract_error_message(response))
      end
    end

    # Handle validation errors (400, 422)
    #
    # @param response [Faraday::Response] the HTTP response
    # @param status_code [Integer] the HTTP status code
    # @raise [ValidationError] the validation error
    def handle_validation_error(response, status_code: 400)
      body = response.body || {}
      message = extract_error_message(response)
      errors = extract_validation_errors(body)

      raise ValidationError.new(message, errors: errors, status_code: status_code)
    end

    # Handle payment errors (402)
    #
    # @param response [Faraday::Response] the HTTP response
    # @raise [PaymentError] the payment error
    def handle_payment_error(response)
      message = extract_error_message(response)

      case message
      when /subscription.*expired/i
        raise PaymentError.subscription_expired
      when /trial.*limit/i
        raise PaymentError.trial_limit_reached
      when /monthly.*limit/i
        raise PaymentError.monthly_limit_reached
      else
        raise PaymentError, message
      end
    end

    # Handle forbidden errors (403)
    #
    # @param response [Faraday::Response] the HTTP response
    # @raise [ForbiddenError] the forbidden error
    def handle_forbidden_error(response)
      body = response.body || {}
      message = extract_error_message(response)

      raise ForbiddenError.insufficient_permissions unless message.include?("suspended")

      # Extract suspension details if available
      reason = body["reason"] || "unknown"
      rate = body["rate"]
      raise ForbiddenError.account_suspended(reason, rate)
    end

    # Handle server errors (5xx)
    #
    # @param response [Faraday::Response] the HTTP response
    # @raise [ServerError] the server error
    def handle_server_error(response)
      message = extract_error_message(response)

      case response.status
      when 500
        raise ServerError.internal_server_error(message)
      when 502
        raise ServerError.bad_gateway(message)
      when 503
        raise ServerError.service_unavailable(message)
      when 504
        raise ServerError.gateway_timeout(message)
      else
        raise ServerError.new(message, status_code: response.status)
      end
    end

    # Extract error message from response
    #
    # @param response [Faraday::Response] the HTTP response
    # @return [String] the error message
    def extract_error_message(response)
      body = response.body
      return "HTTP #{response.status} error" unless body.is_a?(Hash)

      body["message"] || body["error"] || "HTTP #{response.status} error"
    end

    # Extract validation errors from response body
    #
    # @param body [Hash] the response body
    # @return [Hash] field-specific validation errors
    def extract_validation_errors(body)
      return {} unless body.is_a?(Hash)

      errors = body["errors"] || body["validation_errors"] || {}
      return {} unless errors.is_a?(Hash)

      # Convert string values to arrays for consistency
      errors.transform_values { |v| Array(v) }
    end

    # Log HTTP request for debugging
    #
    # @param method [Symbol] the HTTP method
    # @param url [String] the request URL
    # @param data [Hash] the request data
    def log_request(method, url, data)
      puts "[Poodle] #{method.upcase} #{url}"
      puts "[Poodle] Request: #{data.to_json}" unless data.empty?
    end

    # Log HTTP response for debugging
    #
    # @param response [Faraday::Response] the HTTP response
    def log_response(response)
      puts "[Poodle] Response: #{response.status}"
      puts "[Poodle] Body: #{response.body}" if response.body
    end
  end
end
