# frozen_string_literal: true

require_relative "configuration"
require_relative "http_client"
require_relative "email"
require_relative "email_response"
require_relative "errors/validation_error"

module Poodle
  # Main Poodle SDK client for sending emails
  #
  # @example Basic usage
  #   client = Poodle::Client.new(api_key: "your_api_key")
  #   response = client.send(
  #     from: "sender@example.com",
  #     to: "recipient@example.com",
  #     subject: "Hello World",
  #     html: "<h1>Hello!</h1>"
  #   )
  #
  # @example Using configuration object
  #   config = Poodle::Configuration.new(
  #     api_key: "your_api_key",
  #     debug: true
  #   )
  #   client = Poodle::Client.new(config)
  #
  # @example Using environment variables
  #   ENV["POODLE_API_KEY"] = "your_api_key"
  #   client = Poodle::Client.new
  class Client
    # @return [Configuration] the configuration object
    attr_reader :config

    # @return [HttpClient] the HTTP client
    attr_reader :http_client

    # Initialize a new Client
    #
    # @param config_or_api_key [Configuration, String, nil] configuration object or API key
    # @param base_url [String, nil] base URL (only used if first param is API key)
    # @param timeout [Integer, nil] request timeout (only used if first param is API key)
    # @param connect_timeout [Integer, nil] connection timeout (only used if first param is API key)
    # @param debug [Boolean] enable debug mode (only used if first param is API key)
    # @param http_options [Hash] additional HTTP options (only used if first param is API key)
    #
    # @example With API key
    #   client = Poodle::Client.new("your_api_key")
    #
    # @example With configuration
    #   config = Poodle::Configuration.new(api_key: "your_api_key")
    #   client = Poodle::Client.new(config)
    #
    # @example With keyword arguments
    #   client = Poodle::Client.new(
    #     api_key: "your_api_key",
    #     debug: true,
    #     timeout: 60
    #   )
    def initialize(config_or_api_key = nil, **options)
      @config = case config_or_api_key
                when Configuration
                  config_or_api_key
                when String
                  Configuration.new(
                    api_key: config_or_api_key,
                    base_url: options[:base_url],
                    timeout: options[:timeout],
                    connect_timeout: options[:connect_timeout],
                    debug: options.fetch(:debug, false),
                    http_options: options.fetch(:http_options, {})
                  )
                when nil
                  # Support keyword arguments for convenience
                  Configuration.new(**options)
                else
                  raise ArgumentError, "Expected Configuration object, API key string, or nil"
                end

      @http_client = HttpClient.new(@config)
    end

    # Send an email using an Email object or hash
    #
    # @param email [Email, Hash] the email to send
    # @return [EmailResponse] the response from the API
    # @raise [ValidationError] if email data is invalid
    # @raise [Poodle::Error] if the request fails
    #
    # @example With Email object
    #   email = Poodle::Email.new(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello",
    #     html: "<h1>Hello!</h1>"
    #   )
    #   response = client.send_email(email)
    #
    # @example With hash
    #   response = client.send_email({
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello",
    #     text: "Hello!"
    #   })
    def send_email(email)
      email_obj = email.is_a?(Email) ? email : create_email_from_hash(email)

      response_data = @http_client.post("v1/send-email", email_obj.to_h)
      EmailResponse.from_api_response(response_data)
    end

    # Send an email with individual parameters
    #
    # @param from [String] sender email address
    # @param to [String] recipient email address
    # @param subject [String] email subject
    # @param html [String, nil] HTML content
    # @param text [String, nil] plain text content
    # @return [EmailResponse] the response from the API
    # @raise [ValidationError] if email data is invalid
    # @raise [Poodle::Error] if the request fails
    #
    # @example
    #   response = client.send(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Hello World",
    #     html: "<h1>Hello!</h1>",
    #     text: "Hello!"
    #   )
    def send(from:, to:, subject:, html: nil, text: nil)
      email = Email.new(from: from, to: to, subject: subject, html: html, text: text)
      send_email(email)
    end

    # Send an HTML email
    #
    # @param from [String] sender email address
    # @param to [String] recipient email address
    # @param subject [String] email subject
    # @param html [String] HTML content
    # @return [EmailResponse] the response from the API
    # @raise [ValidationError] if email data is invalid
    # @raise [Poodle::Error] if the request fails
    #
    # @example
    #   response = client.send_html(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Newsletter",
    #     html: "<h1>Newsletter</h1><p>Content here</p>"
    #   )
    def send_html(from:, to:, subject:, html:)
      send(from: from, to: to, subject: subject, html: html)
    end

    # Send a plain text email
    #
    # @param from [String] sender email address
    # @param to [String] recipient email address
    # @param subject [String] email subject
    # @param text [String] plain text content
    # @return [EmailResponse] the response from the API
    # @raise [ValidationError] if email data is invalid
    # @raise [Poodle::Error] if the request fails
    #
    # @example
    #   response = client.send_text(
    #     from: "sender@example.com",
    #     to: "recipient@example.com",
    #     subject: "Simple notification",
    #     text: "This is a simple text notification."
    #   )
    def send_text(from:, to:, subject:, text:)
      send(from: from, to: to, subject: subject, text: text)
    end

    # Get the SDK version
    #
    # @return [String] the SDK version
    def version
      @config.class::SDK_VERSION
    end

    private

    # Create an Email object from hash data
    #
    # @param data [Hash] email data
    # @return [Email] the email object
    # @raise [ValidationError] if required fields are missing
    def create_email_from_hash(data)
      validate_required_email_fields(data)
      extract_email_from_hash(data)
    end

    # Validate required email fields
    #
    # @param data [Hash] email data
    # @raise [ValidationError] if required fields are missing
    def validate_required_email_fields(data)
      raise ValidationError.missing_field("from") unless data[:from] || data["from"]
      raise ValidationError.missing_field("to") unless data[:to] || data["to"]
      raise ValidationError.missing_field("subject") unless data[:subject] || data["subject"]
    end

    # Extract email object from hash data
    #
    # @param data [Hash] email data
    # @return [Email] the email object
    def extract_email_from_hash(data)
      Email.new(
        from: data[:from] || data["from"],
        to: data[:to] || data["to"],
        subject: data[:subject] || data["subject"],
        html: data[:html] || data["html"],
        text: data[:text] || data["text"]
      )
    end
  end
end
