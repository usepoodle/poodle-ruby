# frozen_string_literal: true

module Poodle
  # Base exception class for all Poodle SDK errors
  #
  # @example Catching all Poodle errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::Error => e
  #     puts "Poodle error: #{e.message}"
  #     puts "Context: #{e.context}"
  #   end
  class Error < StandardError
    # @return [Hash] additional context information about the error
    attr_reader :context

    # @return [Integer, nil] HTTP status code if available
    attr_reader :status_code

    # Initialize a new error
    #
    # @param message [String] the error message
    # @param context [Hash] additional context information
    # @param status_code [Integer, nil] HTTP status code
    def initialize(message = "", context: {}, status_code: nil)
      @original_message = message
      super(message)
      @context = context
      @status_code = status_code
    end

    # Get the original error message without formatting
    #
    # @return [String] the original error message
    def message
      @original_message
    end

    # Get a string representation of the error with context
    #
    # @return [String] formatted error information
    def to_s
      result = @original_message
      result += " (Status: #{@status_code})" if @status_code
      result += " Context: #{@context}" unless @context.empty?
      result
    end
  end
end
