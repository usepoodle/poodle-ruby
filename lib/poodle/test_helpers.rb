# frozen_string_literal: true

require_relative "email_response"

module Poodle
  # Test utilities and mock classes for testing applications that use Poodle
  #
  # @example RSpec configuration
  #   RSpec.configure do |config|
  #     config.include Poodle::TestHelpers
  #
  #     config.before(:each) do
  #       Poodle.test_mode!
  #     end
  #   end
  #
  # @example Testing email sending
  #   it "sends welcome email" do
  #     expect {
  #       UserMailer.send_welcome(user)
  #     }.to change { Poodle.deliveries.count }.by(1)
  #
  #     email = Poodle.deliveries.last
  #     expect(email[:to]).to eq(user.email)
  #     expect(email[:subject]).to include("Welcome")
  #   end
  module TestHelpers
    # Mock client that captures emails instead of sending them
    class MockClient
      attr_reader :deliveries, :config

      def initialize(config = nil)
        @config = config || create_test_config
        @deliveries = []
      end

      # Mock send method that captures email data
      def send(from:, to:, subject:, html: nil, text: nil)
        delivery = {
          from: from,
          to: to,
          subject: subject,
          html: html,
          text: text,
          sent_at: Time.now
        }

        @deliveries << delivery

        EmailResponse.new(
          success: true,
          message: "Email queued for sending (test mode)",
          data: { test_mode: true, delivery_id: @deliveries.length }
        )
      end

      # Mock send_email method
      def send_email(email)
        if email.is_a?(Hash)
          send(**email.transform_keys(&:to_sym))
        else
          send(
            from: email.from,
            to: email.to,
            subject: email.subject,
            html: email.html,
            text: email.text
          )
        end
      end

      # Mock send_html method
      def send_html(from:, to:, subject:, html:)
        send(from: from, to: to, subject: subject, html: html)
      end

      # Mock send_text method
      def send_text(from:, to:, subject:, text:)
        send(from: from, to: to, subject: subject, text: text)
      end

      # Clear all captured deliveries
      def clear_deliveries
        @deliveries.clear
      end

      # Get the last delivery
      def last_delivery
        @deliveries.last
      end

      # Check if any emails were sent to a specific address
      def sent_to?(email_address)
        @deliveries.any? { |delivery| delivery[:to] == email_address }
      end

      # Get all deliveries sent to a specific address
      def deliveries_to(email_address)
        @deliveries.select { |delivery| delivery[:to] == email_address }
      end

      # Get all deliveries with a specific subject
      def deliveries_with_subject(subject)
        @deliveries.select { |delivery| delivery[:subject].include?(subject) }
      end

      # Get SDK version
      def version
        Poodle::VERSION
      end

      private

      def create_test_config
        # Create a simple configuration without triggering validation
        config = Configuration.allocate
        config.instance_variable_set(:@api_key, "test_key")
        config.instance_variable_set(:@base_url, "https://api.usepoodle.com")
        config.instance_variable_set(:@timeout, 30)
        config.instance_variable_set(:@connect_timeout, 10)
        config.instance_variable_set(:@debug, false)
        config.instance_variable_set(:@http_options, {})
        config
      end
    end

    # Test mode configuration
    module TestMode
      class << self
        attr_accessor :enabled

        def enable!
          @enabled = true
        end

        def disable!
          @enabled = false
          @mock_client = nil
        end

        def enabled?
          @enabled == true
        end

        def mock_client
          @mock_client ||= MockClient.new if enabled?
        end

        def deliveries
          mock_client&.deliveries || []
        end

        def clear_deliveries
          mock_client&.clear_deliveries
        end

        def last_delivery
          mock_client&.last_delivery
        end
      end
    end

    # Helper methods for test assertions
    module Assertions
      # Assert that an email was sent
      def assert_email_sent(count = 1)
        actual_count = Poodle::TestHelpers::TestMode.deliveries.length
        raise "Expected #{count} email(s) to be sent, but #{actual_count} were sent" unless actual_count == count
      end

      # Assert that an email was sent to a specific address
      def assert_email_sent_to(email_address)
        deliveries = Poodle::TestHelpers::TestMode.deliveries
        sent = deliveries.any? { |delivery| delivery[:to] == email_address }
        raise "Expected email to be sent to #{email_address}" unless sent
      end

      # Assert that an email was sent with a specific subject
      def assert_email_sent_with_subject(subject)
        deliveries = Poodle::TestHelpers::TestMode.deliveries
        sent = deliveries.any? { |delivery| delivery[:subject].include?(subject) }
        raise "Expected email to be sent with subject containing '#{subject}'" unless sent
      end

      # Assert that no emails were sent
      def assert_no_emails_sent
        count = Poodle::TestHelpers::TestMode.deliveries.length
        raise "Expected no emails to be sent, but #{count} were sent" unless count.zero?
      end
    end

    # Include assertion methods
    include Assertions

    # Convenience methods for accessing test data
    def poodle_deliveries
      Poodle::TestHelpers::TestMode.deliveries
    end

    def last_poodle_delivery
      Poodle::TestHelpers::TestMode.last_delivery
    end

    def clear_poodle_deliveries
      Poodle::TestHelpers::TestMode.clear_deliveries
    end

    # Create a mock client for testing
    def poodle_mock_client
      Poodle::TestHelpers::MockClient.new
    end
  end
end

# Convenience methods for global access
module Poodle
  def self.test_mode!
    TestHelpers::TestMode.enable!
  end

  def self.disable_test_mode!
    TestHelpers::TestMode.disable!
  end

  def self.test_mode?
    TestHelpers::TestMode.enabled?
  end

  def self.deliveries
    TestHelpers::TestMode.deliveries
  end

  def self.clear_deliveries
    TestHelpers::TestMode.clear_deliveries
  end

  def self.last_delivery
    TestHelpers::TestMode.last_delivery
  end

  def self.mock_client
    TestHelpers::MockClient.new
  end
end
