# frozen_string_literal: true

module Poodle
  # Email response model representing the API response for email operations
  #
  # @example Checking response status
  #   response = client.send_email(email)
  #   if response.success?
  #     puts "Email sent: #{response.message}"
  #   else
  #     puts "Failed: #{response.message}"
  #   end
  #
  # @example Converting to hash
  #   response_data = response.to_h
  #   puts response_data[:success]
  #   puts response_data[:message]
  class EmailResponse
    # @return [Boolean] whether the email was successfully queued
    attr_reader :success

    # @return [String] response message from the API
    attr_reader :message

    # @return [Hash] additional response data
    attr_reader :data

    # Initialize a new EmailResponse
    #
    # @param success [Boolean] whether the operation was successful
    # @param message [String] response message
    # @param data [Hash] additional response data
    def initialize(success:, message:, data: {})
      @success = success
      @message = message
      @data = data
      freeze # Make the object immutable
    end

    # Create an EmailResponse from API response data
    #
    # @param response_data [Hash] the API response data
    # @return [EmailResponse] the email response object
    def self.from_api_response(response_data)
      new(
        success: response_data[:success] || response_data["success"] || false,
        message: response_data[:message] || response_data["message"] || "",
        data: response_data
      )
    end

    # Check if email was successfully queued
    #
    # @return [Boolean] true if successful
    def success?
      @success
    end

    # Check if email sending failed
    #
    # @return [Boolean] true if failed
    def failed?
      !@success
    end

    # Convert response to hash
    #
    # @return [Hash] response data as hash
    def to_h
      {
        success: @success,
        message: @message,
        data: @data
      }
    end

    # Convert response to JSON string
    #
    # @return [String] response data as JSON
    def to_json(*args)
      require "json"
      to_h.to_json(*args)
    end

    # Get a string representation of the response
    #
    # @return [String] formatted response information
    def to_s
      status = @success ? "SUCCESS" : "FAILED"
      "EmailResponse[#{status}]: #{@message}"
    end

    # Get detailed string representation for debugging
    #
    # @return [String] detailed response information
    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} " \
        "success=#{@success} message=#{@message.inspect} data=#{@data.inspect}>"
    end
  end
end
