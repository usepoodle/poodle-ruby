# frozen_string_literal: true

require "rails/railtie"

module Poodle
  module Rails
    # Rails Railtie for automatic Poodle integration
    class Railtie < ::Rails::Railtie
      # Add Poodle configuration to Rails generators
      config.generators do |g|
        g.test_framework :rspec
      end

      # Initialize Poodle after Rails application is initialized
      initializer "poodle.configure" do |app|
        # Auto-configure Poodle if credentials or environment variables are present
        if ENV["POODLE_API_KEY"] ||
           (app.credentials.respond_to?(:poodle_api_key) && app.credentials.poodle_api_key)
          Poodle::Rails.auto_configure!
        end
      end

      # Add Poodle logger integration
      initializer "poodle.logger" do |_app|
        # Integrate with Rails logger if debug mode is enabled
        if Poodle::Rails.configured? && Poodle::Rails.configuration.debug?
          # Override the HTTP client logging to use Rails logger
          Poodle::HttpClient.class_eval do
            private

            def log_request(method, url, data)
              ::Rails.logger.debug "[Poodle] #{method.upcase} #{url}"
              ::Rails.logger.debug "[Poodle] Request: #{data.to_json}" unless data.empty?
            end

            def log_response(response)
              ::Rails.logger.debug "[Poodle] Response: #{response.status}"
              ::Rails.logger.debug "[Poodle] Body: #{response.body}" if response.body
            end
          end
        end
      end

      # Add rake tasks
      rake_tasks do
        load "poodle/rails/tasks.rake"
      end
    end
  end
end
