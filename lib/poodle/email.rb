# frozen_string_literal: true

require "uri"
require_relative "configuration"
require_relative "errors/validation_error"

module Poodle
  # Email model representing an email to be sent
  #
  # @example Creating an email
  #   email = Poodle::Email.new(
  #     from: "sender@example.com",
  #     to: "recipient@example.com",
  #     subject: "Hello World",
  #     html: "<h1>Hello!</h1>",
  #     text: "Hello!"
  #   )
  #
  # @example HTML only email
  #   email = Poodle::Email.new(
  #     from: "sender@example.com",
  #     to: "recipient@example.com",
  #     subject: "Newsletter",
  #     html: "<h1>Newsletter</h1><p>Content here</p>"
  #   )
  #
  # @example Text only email
  #   email = Poodle::Email.new(
  #     from: "sender@example.com",
  #     to: "recipient@example.com",
  #     subject: "Simple notification",
  #     text: "This is a simple text notification."
  #   )
  class Email
    # @return [String] sender email address
    attr_reader :from

    # @return [String] recipient email address
    attr_reader :to

    # @return [String] email subject
    attr_reader :subject

    # @return [String, nil] HTML content
    attr_reader :html

    # @return [String, nil] plain text content
    attr_reader :text

    # Initialize a new Email
    #
    # @param from [String] sender email address
    # @param to [String] recipient email address
    # @param subject [String] email subject
    # @param html [String, nil] HTML content
    # @param text [String, nil] plain text content
    #
    # @raise [ValidationError] if any field is invalid
    def initialize(from:, to:, subject:, html: nil, text: nil)
      @from = from
      @to = to
      @subject = subject
      @html = html
      @text = text

      validate!
      freeze # Make the object immutable
    end

    # Convert email to hash for API request
    #
    # @return [Hash] email data as hash
    def to_h
      data = {
        from: @from,
        to: @to,
        subject: @subject
      }

      data[:html] = @html if @html
      data[:text] = @text if @text

      data
    end

    # Convert email to JSON string
    #
    # @return [String] email data as JSON
    def to_json(*args)
      require "json"
      to_h.to_json(*args)
    end

    # Check if email has HTML content
    #
    # @return [Boolean] true if HTML content is present
    def html?
      !@html.nil? && !@html.empty?
    end

    # Check if email has text content
    #
    # @return [Boolean] true if text content is present
    def text?
      !@text.nil? && !@text.empty?
    end

    # Check if email is multipart (has both HTML and text)
    #
    # @return [Boolean] true if both HTML and text content are present
    def multipart?
      html? && text?
    end

    # Get the size of the email content in bytes
    #
    # @return [Integer] total size of HTML and text content
    def content_size
      size = 0
      size += @html.bytesize if @html
      size += @text.bytesize if @text
      size
    end

    private

    # Validate email data
    #
    # @raise [ValidationError] if any validation fails
    def validate!
      validate_required_fields!
      validate_email_addresses!
      validate_content!
      validate_content_size!
    end

    # Validate required fields
    #
    # @raise [ValidationError] if any required field is missing
    def validate_required_fields!
      raise ValidationError.missing_field("from") if @from.nil? || @from.empty?
      raise ValidationError.missing_field("to") if @to.nil? || @to.empty?
      raise ValidationError.missing_field("subject") if @subject.nil? || @subject.empty?
    end

    # Validate email addresses
    #
    # @raise [ValidationError] if any email address is invalid
    def validate_email_addresses!
      raise ValidationError.invalid_email(@from, field: "from") unless valid_email?(@from)
      raise ValidationError.invalid_email(@to, field: "to") unless valid_email?(@to)
    end

    # Validate content presence
    #
    # @raise [ValidationError] if no content is provided
    def validate_content!
      return if html? || text?

      raise ValidationError.invalid_content
    end

    # Validate content size
    #
    # @raise [ValidationError] if content is too large
    def validate_content_size!
      max_size = Configuration::MAX_CONTENT_SIZE

      raise ValidationError.content_too_large("html", max_size) if @html && @html.bytesize > max_size

      return unless @text && @text.bytesize > max_size

      raise ValidationError.content_too_large("text", max_size)
    end

    # Check if an email address is valid
    #
    # @param email [String] the email address to validate
    # @return [Boolean] true if the email is valid
    def valid_email?(email)
      return false if email.nil? || email.empty?

      # Basic email validation using URI::MailTo
      uri = URI::MailTo.build([email, nil])
      uri.to_s == "mailto:#{email}"
    rescue URI::InvalidComponentError, ArgumentError
      false
    end
  end
end
