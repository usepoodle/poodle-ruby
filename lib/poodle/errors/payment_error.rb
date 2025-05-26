# frozen_string_literal: true

require_relative "base_error"

module Poodle
  # Exception raised when payment is required (402 Payment Required)
  #
  # @example Handling payment errors
  #   begin
  #     client.send_email(email)
  #   rescue Poodle::PaymentError => e
  #     puts "Payment required: #{e.message}"
  #     puts "Upgrade URL: #{e.upgrade_url}" if e.upgrade_url
  #   end
  class PaymentError < Error
    # @return [String, nil] URL to upgrade subscription
    attr_reader :upgrade_url

    # Initialize a new PaymentError
    #
    # @param message [String] the error message
    # @param upgrade_url [String, nil] URL to upgrade subscription
    # @param context [Hash] additional context information
    def initialize(message = "Payment required", upgrade_url: nil, context: {})
      @upgrade_url = upgrade_url
      super(message, context: context.merge(upgrade_url: upgrade_url), status_code: 402)
    end

    # Create a PaymentError for subscription expired
    #
    # @return [PaymentError] the payment error
    def self.subscription_expired
      new(
        "Subscription expired. Please renew your subscription to continue sending emails.",
        upgrade_url: "https://app.usepoodle.com/upgrade",
        context: { error_type: "subscription_expired" }
      )
    end

    # Create a PaymentError for trial limit reached
    #
    # @return [PaymentError] the payment error
    def self.trial_limit_reached
      new(
        "Trial limit reached. Please upgrade to a paid plan to continue sending emails.",
        upgrade_url: "https://app.usepoodle.com/upgrade",
        context: { error_type: "trial_limit_reached" }
      )
    end

    # Create a PaymentError for monthly limit reached
    #
    # @return [PaymentError] the payment error
    def self.monthly_limit_reached
      new(
        "Monthly email limit reached. Please upgrade your plan to send more emails.",
        upgrade_url: "https://app.usepoodle.com/upgrade",
        context: { error_type: "monthly_limit_reached" }
      )
    end

    # Create a PaymentError for monthly limit exceeded (alias for monthly_limit_reached)
    #
    # @return [PaymentError] the payment error
    def self.monthly_limit_exceeded
      new(
        "Monthly email limit exceeded. Please upgrade your plan to send more emails.",
        upgrade_url: "https://app.usepoodle.com/upgrade",
        context: { error_type: "monthly_limit_exceeded" }
      )
    end
  end
end
