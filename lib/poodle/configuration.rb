# frozen_string_literal: true

require "uri"

module Poodle
  # Configuration class for Poodle SDK settings
  #
  # @example Basic configuration
  #   config = Poodle::Configuration.new(api_key: "your_api_key")
  #
  # @example Using environment variables
  #   ENV["POODLE_API_KEY"] = "your_api_key"
  #   config = Poodle::Configuration.new
  #
  # @example Full configuration
  #   config = Poodle::Configuration.new(
  #     api_key: "your_api_key",
  #     base_url: "https://api.usepoodle.com",
  #     timeout: 30,
  #     connect_timeout: 10,
  #     debug: true
  #   )
  class Configuration
    # Default API base URL
    DEFAULT_BASE_URL = "https://api.usepoodle.com"

    # Default timeout in seconds
    DEFAULT_TIMEOUT = 30

    # Default connect timeout in seconds
    DEFAULT_CONNECT_TIMEOUT = 10

    # Maximum content size in bytes (10MB)
    MAX_CONTENT_SIZE = 10 * 1024 * 1024

    # SDK version
    SDK_VERSION = Poodle::VERSION

    # @return [String] the API key for authentication
    attr_reader :api_key

    # @return [String] the base URL for the API
    attr_reader :base_url

    # @return [Integer] the request timeout in seconds
    attr_reader :timeout

    # @return [Integer] the connection timeout in seconds
    attr_reader :connect_timeout

    # @return [Boolean] whether debug mode is enabled
    attr_reader :debug

    # @return [Hash] additional HTTP client options
    attr_reader :http_options

    # Initialize a new Configuration
    #
    # @param api_key [String, nil] API key (defaults to POODLE_API_KEY env var)
    # @param base_url [String, nil] Base URL (defaults to POODLE_BASE_URL env var or DEFAULT_BASE_URL)
    # @param timeout [Integer, nil] Request timeout (defaults to POODLE_TIMEOUT env var or DEFAULT_TIMEOUT)
    # @param connect_timeout [Integer, nil] Connect timeout (defaults to POODLE_CONNECT_TIMEOUT env var or
    #   DEFAULT_CONNECT_TIMEOUT)
    # @param debug [Boolean] Enable debug mode (defaults to POODLE_DEBUG env var or false)
    # @param http_options [Hash] Additional HTTP client options
    #
    # @raise [ArgumentError] if api_key is missing or invalid
    # @raise [ArgumentError] if base_url is invalid
    # @raise [ArgumentError] if timeout values are invalid
    def initialize(**options)
      api_key = options[:api_key]
      base_url = options[:base_url]
      timeout = options[:timeout]
      connect_timeout = options[:connect_timeout]
      debug = options.fetch(:debug, false)
      http_options = options.fetch(:http_options, {})
      @api_key = api_key || ENV.fetch("POODLE_API_KEY", nil)
      @base_url = base_url || ENV["POODLE_BASE_URL"] || DEFAULT_BASE_URL
      @timeout = timeout || ENV.fetch("POODLE_TIMEOUT", DEFAULT_TIMEOUT).to_i
      @connect_timeout = connect_timeout || ENV.fetch("POODLE_CONNECT_TIMEOUT", DEFAULT_CONNECT_TIMEOUT).to_i
      @debug = debug || ENV["POODLE_DEBUG"] == "true"
      @http_options = http_options

      validate!
    end

    # Get the User-Agent string for HTTP requests
    #
    # @return [String] the User-Agent string
    def user_agent
      "poodle-ruby/#{SDK_VERSION} (Ruby #{RUBY_VERSION})"
    end

    # Get the full URL for an endpoint
    #
    # @param endpoint [String] the API endpoint
    # @return [String] the full URL
    def url_for(endpoint)
      "#{@base_url}/#{endpoint.gsub(%r{^/}, '')}"
    end

    # Check if debug mode is enabled
    #
    # @return [Boolean] true if debug mode is enabled
    def debug?
      @debug
    end

    private

    # Validate the configuration
    #
    # @raise [ArgumentError] if any configuration is invalid
    def validate!
      raise ArgumentError, "API key is required" if @api_key.nil? || @api_key.empty?

      validate_url!(@base_url, "base_url")
      validate_timeout!(@timeout, "timeout")
      validate_timeout!(@connect_timeout, "connect_timeout")
    end

    # Validate a URL
    #
    # @param url [String] the URL to validate
    # @param field [String] the field name for error messages
    # @raise [ArgumentError] if the URL is invalid
    def validate_url!(url, field)
      return if url.nil? || url.empty?

      uri = URI.parse(url)
      raise ArgumentError, "#{field} must be a valid HTTP or HTTPS URL" unless %w[http https].include?(uri.scheme)
    rescue URI::InvalidURIError
      raise ArgumentError, "#{field} must be a valid URL"
    end

    # Validate a timeout value
    #
    # @param value [Integer] the timeout value
    # @param field [String] the field name for error messages
    # @raise [ArgumentError] if the timeout is invalid
    def validate_timeout!(value, field)
      raise ArgumentError, "#{field} must be a positive integer" unless value.is_a?(Integer) && value.positive?
    end
  end
end
