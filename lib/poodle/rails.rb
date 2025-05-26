# frozen_string_literal: true

require_relative "configuration"
require_relative "client"

module Poodle
  # Rails integration module for Poodle SDK
  #
  # @example Rails initializer (config/initializers/poodle.rb)
  #   Poodle::Rails.configure do |config|
  #     config.api_key = Rails.application.credentials.poodle_api_key
  #     config.debug = Rails.env.development?
  #   end
  #
  # @example Using in Rails controllers
  #   class NotificationController < ApplicationController
  #     def send_welcome_email
  #       response = Poodle::Rails.client.send(
  #         from: "welcome@example.com",
  #         to: params[:email],
  #         subject: "Welcome!",
  #         html: render_to_string("welcome_email")
  #       )
  #
  #       if response.success?
  #         render json: { status: "sent" }
  #       else
  #         render json: { error: response.message }, status: :unprocessable_entity
  #       end
  #     end
  #   end
  module Rails
    class << self
      # @return [Configuration, nil] the global configuration
      attr_reader :configuration

      # Configure Poodle for Rails applications
      #
      # @yield [Configuration] the configuration object
      # @return [Configuration] the configuration object
      #
      # @example
      #   Poodle::Rails.configure do |config|
      #     config.api_key = Rails.application.credentials.poodle_api_key
      #     config.base_url = "https://api.usepoodle.com"
      #     config.timeout = 30
      #     config.debug = Rails.env.development?
      #   end
      def configure
        @configuration = Configuration.new
        yield(@configuration) if block_given?
        @configuration
      end

      # Get the global Poodle client for Rails
      #
      # @return [Client] the configured client
      # @raise [RuntimeError] if not configured
      #
      # @example
      #   client = Poodle::Rails.client
      #   response = client.send(email_params)
      def client
        raise "Poodle not configured. Call Poodle::Rails.configure first." unless @configuration

        @client ||= Client.new(@configuration)
      end

      # Reset the configuration and client (useful for testing)
      #
      # @return [void]
      def reset!
        @configuration = nil
        @client = nil
      end

      # Check if Poodle is configured
      #
      # @return [Boolean] true if configured
      def configured?
        !@configuration.nil?
      end

      # Get configuration from Rails environment
      #
      # @return [Hash] configuration hash from Rails
      def rails_config
        return {} unless defined?(::Rails)

        begin
          ::Rails.application.config_for(:poodle)
        rescue StandardError
          {}
        end
      end

      # Auto-configure from Rails credentials and environment
      #
      # @return [Configuration] the configuration object
      #
      # @example In Rails initializer
      #   Poodle::Rails.auto_configure!
      def auto_configure!
        config_hash = rails_config

        configure do |config|
          configure_api_key(config, config_hash)
          configure_base_url(config, config_hash)
          configure_timeout(config, config_hash)
          configure_debug_mode(config, config_hash)
        end
      end

      private

      # Configure API key from various sources
      #
      # @param config [Configuration] the configuration object
      # @param config_hash [Hash] configuration from Rails
      def configure_api_key(config, config_hash)
        # Try Rails credentials first, then environment variables
        if defined?(::Rails) && ::Rails.application.credentials.respond_to?(:poodle_api_key)
          config.api_key = ::Rails.application.credentials.poodle_api_key
        end

        config.api_key ||= config_hash[:api_key] || ENV.fetch("POODLE_API_KEY", nil)
      end

      # Configure base URL from various sources
      #
      # @param config [Configuration] the configuration object
      # @param config_hash [Hash] configuration from Rails
      def configure_base_url(config, config_hash)
        config.base_url = config_hash[:base_url] || ENV["POODLE_BASE_URL"] || config.base_url
      end

      # Configure timeout from various sources
      #
      # @param config [Configuration] the configuration object
      # @param config_hash [Hash] configuration from Rails
      def configure_timeout(config, config_hash)
        config.timeout = config_hash[:timeout] || ENV["POODLE_TIMEOUT"]&.to_i || config.timeout
      end

      # Configure debug mode from various sources
      #
      # @param config [Configuration] the configuration object
      # @param config_hash [Hash] configuration from Rails
      def configure_debug_mode(config, config_hash)
        config.debug = config_hash[:debug] || ENV["POODLE_DEBUG"] == "true" ||
                       (defined?(::Rails) && ::Rails.env.development?)
      end
    end
  end
end

# Auto-configure if Rails is detected
require_relative "rails/railtie" if defined?(Rails)
