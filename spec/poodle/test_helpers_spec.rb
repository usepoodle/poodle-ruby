# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/poodle/test_helpers"

RSpec.describe Poodle::TestHelpers do
  describe "test mode" do
    before do
      Poodle.test_mode!
    end

    after do
      Poodle.disable_test_mode!
    end

    it "enables test mode" do
      expect(Poodle.test_mode?).to be true
    end

    it "captures email deliveries using mock client" do
      client = Poodle.mock_client

      expect do
        client.send(
          from: "test@example.com",
          to: "recipient@example.com",
          subject: "Test",
          html: "<p>Test</p>"
        )
      end.to change { client.deliveries.count }.by(1)

      delivery = client.last_delivery
      expect(delivery[:from]).to eq("test@example.com")
      expect(delivery[:to]).to eq("recipient@example.com")
      expect(delivery[:subject]).to eq("Test")
      expect(delivery[:html]).to eq("<p>Test</p>")
    end

    it "clears deliveries" do
      client = Poodle.mock_client
      client.send(from: "test@example.com", to: "recipient@example.com", subject: "Test", html: "<p>Test</p>")

      expect(client.deliveries.count).to eq(1)

      client.clear_deliveries
      expect(client.deliveries.count).to eq(0)
    end
  end

  describe "MockClient" do
    let(:mock_client) { described_class::MockClient.new }

    it "captures email data" do
      response = mock_client.send(
        from: "test@example.com",
        to: "recipient@example.com",
        subject: "Test",
        html: "<p>Test</p>"
      )

      expect(response.success?).to be true
      expect(response.message).to include("test mode")
      expect(mock_client.deliveries.count).to eq(1)
    end

    it "supports send_html method" do
      response = mock_client.send_html(
        from: "test@example.com",
        to: "recipient@example.com",
        subject: "Test",
        html: "<p>Test</p>"
      )

      expect(response.success?).to be true
      expect(mock_client.deliveries.count).to eq(1)
    end

    it "supports send_text method" do
      response = mock_client.send_text(
        from: "test@example.com",
        to: "recipient@example.com",
        subject: "Test",
        text: "Test content"
      )

      expect(response.success?).to be true
      expect(mock_client.deliveries.count).to eq(1)
    end

    it "checks if email was sent to specific address" do
      mock_client.send(
        from: "test@example.com",
        to: "recipient@example.com",
        subject: "Test",
        html: "<p>Test</p>"
      )

      expect(mock_client.sent_to?("recipient@example.com")).to be true
      expect(mock_client.sent_to?("other@example.com")).to be false
    end

    it "filters deliveries by recipient" do
      mock_client.send(from: "test@example.com", to: "user1@example.com", subject: "Test 1", html: "<p>Test 1</p>")
      mock_client.send(from: "test@example.com", to: "user2@example.com", subject: "Test 2", html: "<p>Test 2</p>")
      mock_client.send(from: "test@example.com", to: "user1@example.com", subject: "Test 3", html: "<p>Test 3</p>")

      deliveries = mock_client.deliveries_to("user1@example.com")
      expect(deliveries.count).to eq(2)
      expect(deliveries.map { |d| d[:subject] }).to contain_exactly("Test 1", "Test 3")
    end

    it "filters deliveries by subject" do
      mock_client.send(from: "test@example.com", to: "user@example.com", subject: "Welcome Email", html: "<p>Welcome</p>")
      mock_client.send(from: "test@example.com", to: "user@example.com", subject: "Newsletter", html: "<p>News</p>")
      mock_client.send(from: "test@example.com", to: "user@example.com", subject: "Welcome Back", html: "<p>Welcome back</p>")

      deliveries = mock_client.deliveries_with_subject("Welcome")
      expect(deliveries.count).to eq(2)
      expect(deliveries.map { |d| d[:subject] }).to contain_exactly("Welcome Email", "Welcome Back")
    end
  end

  describe "assertions" do
    include described_class

    before do
      Poodle.test_mode!
    end

    after do
      Poodle.disable_test_mode!
    end

    it "asserts email was sent using global test mode" do
      # Use the global test mode mock client
      Poodle::TestHelpers::TestMode.mock_client.send(from: "test@example.com", to: "recipient@example.com", subject: "Test", html: "<p>Test</p>")

      expect { assert_email_sent(1) }.not_to raise_error
      expect { assert_email_sent(2) }.to raise_error(/Expected 2 email\(s\) to be sent, but 1 were sent/)
    end

    it "asserts email was sent to specific address" do
      Poodle::TestHelpers::TestMode.mock_client.send(from: "test@example.com", to: "recipient@example.com", subject: "Test", html: "<p>Test</p>")

      expect { assert_email_sent_to("recipient@example.com") }.not_to raise_error
      expect { assert_email_sent_to("other@example.com") }.to raise_error(/Expected email to be sent to other@example.com/)
    end

    it "asserts email was sent with specific subject" do
      Poodle::TestHelpers::TestMode.mock_client.send(from: "test@example.com", to: "recipient@example.com", subject: "Welcome Email", html: "<p>Test</p>")

      expect { assert_email_sent_with_subject("Welcome") }.not_to raise_error
      expect { assert_email_sent_with_subject("Goodbye") }.to raise_error(/Expected email to be sent with subject containing 'Goodbye'/)
    end

    it "asserts no emails were sent" do
      # Clear any existing deliveries first
      Poodle.clear_deliveries
      expect { assert_no_emails_sent }.not_to raise_error

      Poodle::TestHelpers::TestMode.mock_client.send(from: "test@example.com", to: "recipient@example.com", subject: "Test", html: "<p>Test</p>")

      expect { assert_no_emails_sent }.to raise_error(/Expected no emails to be sent, but 1 were sent/)
    end
  end
end
