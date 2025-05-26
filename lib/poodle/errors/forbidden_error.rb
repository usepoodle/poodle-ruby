# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when access is forbidden (403 Forbidden)
  #
  # @example Handling forbidden errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::ForbiddenError => e
  #     puts "Access forbidden: #{e.message}"
  #     puts "Reason: #{e.reason}" if e.reason
  #   end
  class ForbiddenError < Error
    # @return [String, nil] reason for the forbidden access
    attr_reader :reason

    # Initialize a new ForbiddenError
    #
    # @param message [String] the error message
    # @param reason [String, nil] reason for the forbidden access
    # @param context [Hash] additional context information
    def initialize(message = "Access forbidden", reason: nil, context: {})
      @reason = reason
      super(message, context: context.merge(reason: reason), status_code: 403)
    end

    # Create a ForbiddenError for account suspended
    #
    # @param reason [String] the suspension reason
    # @param rate [Float, nil] the suspension rate if applicable
    # @return [ForbiddenError] the forbidden error
    def self.account_suspended(reason, rate = nil)
      message = "Account suspended: #{reason}"
      message += " (Rate: #{rate})" if rate

      new(
        message,
        reason: reason,
        context: { error_type: "account_suspended", suspension_rate: rate }
      )
    end

    # Create a ForbiddenError for insufficient permissions
    #
    # @return [ForbiddenError] the forbidden error
    def self.insufficient_permissions
      new(
        "API key does not have sufficient permissions for this operation.",
        reason: "insufficient_permissions",
        context: { error_type: "insufficient_permissions" }
      )
    end
  end
end
