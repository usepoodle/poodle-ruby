# frozen_string_literal: true

require_relative "poodle/version"
require_relative "poodle/configuration"
require_relative "poodle/email"
require_relative "poodle/email_response"
require_relative "poodle/client"

# Error classes
require_relative "poodle/errors/base_error"
require_relative "poodle/errors/validation_error"
require_relative "poodle/errors/authentication_error"
require_relative "poodle/errors/payment_error"
require_relative "poodle/errors/forbidden_error"
require_relative "poodle/errors/rate_limit_error"
require_relative "poodle/errors/network_error"
require_relative "poodle/errors/server_error"

# Additional modules (loaded on demand)
# require_relative "poodle/test_helpers"

# Rails integration (optional)
begin
  require_relative "poodle/rails" if defined?(Rails)
rescue LoadError
  # Rails not available, skip Rails integration
end

# Ruby SDK for the Poodle email sending API
#
# @example Quick start
#   require "poodle"
#
#   client = Poodle::Client.new(api_key: "your_api_key")
#   response = client.send(
#     from: "sender@example.com",
#     to: "recipient@example.com",
#     subject: "Hello World",
#     html: "<h1>Hello!</h1>"
#   )
#
#   puts "Email sent!" if response.success?
#
# @example Using environment variables
#   ENV["POODLE_API_KEY"] = "your_api_key"
#   client = Poodle::Client.new
#
# @example Error handling
#   begin
#     response = client.send(email_data)
#   rescue Poodle::ValidationError => e
#     puts "Validation failed: #{e.errors}"
#   rescue Poodle::AuthenticationError => e
#     puts "Authentication failed: #{e.message}"
#   rescue Poodle::RateLimitError => e
#     puts "Rate limited. Retry after: #{e.retry_after} seconds"
#   rescue Poodle::Error => e
#     puts "Poodle error: #{e.message}"
#   end
module Poodle
  # Convenience method to create a new client
  #
  # @param args [Array] arguments to pass to Client.new
  # @param kwargs [Hash] keyword arguments to pass to Client.new
  # @return [Client] a new client instance
  #
  # @example
  #   client = Poodle.new(api_key: "your_api_key")
  #   # equivalent to: Poodle::Client.new(api_key: "your_api_key")
  def self.new(*args, **kwargs)
    Client.new(*args, **kwargs)
  end

  # Get the SDK version
  #
  # @return [String] the SDK version
  def self.version
    VERSION
  end
end
