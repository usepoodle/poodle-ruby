# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::Client do
  let(:api_key) { "test_api_key" }
  let(:config) { Poodle::Configuration.new(api_key: api_key) }
  let(:mock_http_client) { instance_double(Poodle::HttpClient) }

  describe "#initialize" do
    context "with Configuration object" do
      it "accepts a Configuration object" do
        client = described_class.new(config)
        expect(client.config).to eq(config)
        expect(client.http_client).to be_a(Poodle::HttpClient)
      end
    end

    context "with API key string" do
      it "creates configuration from API key" do
        client = described_class.new(api_key)
        expect(client.config.api_key).to eq(api_key)
        expect(client.http_client).to be_a(Poodle::HttpClient)
      end

      it "accepts additional options with API key" do
        client = described_class.new(api_key, debug: true, timeout: 60)
        expect(client.config.api_key).to eq(api_key)
        expect(client.config.debug?).to be true
        expect(client.config.timeout).to eq(60)
      end
    end

    context "with keyword arguments" do
      it "creates configuration from keyword arguments" do
        client = described_class.new(api_key: api_key, debug: true)
        expect(client.config.api_key).to eq(api_key)
        expect(client.config.debug?).to be true
      end
    end

    context "with nil" do
      it "creates configuration from environment or defaults" do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:fetch).with("POODLE_API_KEY", nil).and_return("test_env_api_key")
        allow(ENV).to receive(:[]).with("POODLE_BASE_URL").and_return(nil)
        allow(ENV).to receive(:[]).with("POODLE_DEBUG").and_return(nil)
        allow(ENV).to receive(:fetch).with("POODLE_TIMEOUT", anything).and_return("30")
        allow(ENV).to receive(:fetch).with("POODLE_CONNECT_TIMEOUT", anything).and_return("10")
        client = described_class.new
        expect(client.config).to be_a(Poodle::Configuration)
        expect(client.http_client).to be_a(Poodle::HttpClient)
      end
    end

    context "with invalid argument" do
      it "raises ArgumentError for invalid argument type" do
        expect do
          described_class.new(123)
        end.to raise_error(ArgumentError, /Expected Configuration object, API key string, or nil/)
      end
    end
  end

  describe "#send_email" do
    let(:client) { described_class.new(config) }
    let(:email) do
      Poodle::Email.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )
    end
    let(:response_data) { { "success" => true, "message" => "Email queued" } }

    before do
      allow(Poodle::HttpClient).to receive(:new).and_return(mock_http_client)
    end

    context "with Email object" do
      it "sends email and returns EmailResponse" do
        expect(mock_http_client).to receive(:post)
          .with("v1/send-email", email.to_h)
          .and_return(response_data)

        response = client.send_email(email)
        expect(response).to be_a(Poodle::EmailResponse)
        expect(response.success?).to be true
        expect(response.message).to eq("Email queued")
      end
    end

    context "with hash" do
      let(:email_hash) do
        {
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>"
        }
      end

      it "creates Email object from hash and sends" do
        expect(mock_http_client).to receive(:post)
          .with("v1/send-email", email_hash)
          .and_return(response_data)

        response = client.send_email(email_hash)
        expect(response).to be_a(Poodle::EmailResponse)
        expect(response.success?).to be true
      end

      it "supports string keys in hash" do
        string_key_hash = {
          "from" => "sender@example.com",
          "to" => "recipient@example.com",
          "subject" => "Test Subject",
          "html" => "<h1>Hello</h1>"
        }

        expect(mock_http_client).to receive(:post)
          .with("v1/send-email", email_hash)
          .and_return(response_data)

        response = client.send_email(string_key_hash)
        expect(response).to be_a(Poodle::EmailResponse)
      end

      it "raises ValidationError for missing required fields" do
        invalid_hash = { from: "sender@example.com" }

        expect do
          client.send_email(invalid_hash)
        end.to raise_error(Poodle::ValidationError, /Missing required field/)
      end
    end
  end

  describe "#send" do
    let(:client) { described_class.new(config) }
    let(:response_data) { { "success" => true, "message" => "Email queued" } }

    before do
      allow(Poodle::HttpClient).to receive(:new).and_return(mock_http_client)
    end

    it "sends email with individual parameters" do
      expected_data = {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: "Hello World"
      }

      expect(mock_http_client).to receive(:post)
        .with("v1/send-email", expected_data)
        .and_return(response_data)

      response = client.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: "Hello World"
      )

      expect(response).to be_a(Poodle::EmailResponse)
      expect(response.success?).to be true
    end

    it "sends email with only HTML content" do
      expected_data = {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      }

      expect(mock_http_client).to receive(:post)
        .with("v1/send-email", expected_data)
        .and_return(response_data)

      response = client.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(response).to be_a(Poodle::EmailResponse)
    end

    it "sends email with only text content" do
      expected_data = {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      }

      expect(mock_http_client).to receive(:post)
        .with("v1/send-email", expected_data)
        .and_return(response_data)

      response = client.send(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(response).to be_a(Poodle::EmailResponse)
    end
  end

  describe "#send_html" do
    let(:client) { described_class.new(config) }
    let(:response_data) { { "success" => true, "message" => "Email queued" } }

    before do
      allow(Poodle::HttpClient).to receive(:new).and_return(mock_http_client)
    end

    it "sends HTML email" do
      expected_data = {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      }

      expect(mock_http_client).to receive(:post)
        .with("v1/send-email", expected_data)
        .and_return(response_data)

      response = client.send_html(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(response).to be_a(Poodle::EmailResponse)
      expect(response.success?).to be true
    end
  end

  describe "#send_text" do
    let(:client) { described_class.new(config) }
    let(:response_data) { { "success" => true, "message" => "Email queued" } }

    before do
      allow(Poodle::HttpClient).to receive(:new).and_return(mock_http_client)
    end

    it "sends text email" do
      expected_data = {
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      }

      expect(mock_http_client).to receive(:post)
        .with("v1/send-email", expected_data)
        .and_return(response_data)

      response = client.send_text(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(response).to be_a(Poodle::EmailResponse)
      expect(response.success?).to be true
    end
  end

  describe "#version" do
    let(:client) { described_class.new(config) }

    it "returns the SDK version" do
      expect(client.version).to eq(Poodle::Configuration::SDK_VERSION)
    end
  end

  describe "private methods" do
    let(:client) { described_class.new(config) }

    describe "#create_email_from_hash" do
      it "validates required fields" do
        expect do
          client.__send__(:create_email_from_hash, { from: "test@example.com" })
        end.to raise_error(Poodle::ValidationError, /Missing required field/)
      end

      it "creates email from valid hash" do
        hash = {
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>"
        }

        email = client.__send__(:create_email_from_hash, hash)
        expect(email).to be_a(Poodle::Email)
        expect(email.from).to eq("sender@example.com")
      end
    end

    describe "#validate_required_email_fields" do
      it "raises error for missing from field" do
        expect do
          client.__send__(:validate_required_email_fields, { to: "test@example.com" })
        end.to raise_error(Poodle::ValidationError, /Missing required field/)
      end

      it "raises error for missing to field" do
        expect do
          client.__send__(:validate_required_email_fields, { from: "test@example.com" })
        end.to raise_error(Poodle::ValidationError, /Missing required field/)
      end

      it "raises error for missing subject field" do
        expect do
          client.__send__(:validate_required_email_fields, {
                            from: "test@example.com",
                            to: "test@example.com"
                          })
        end.to raise_error(Poodle::ValidationError, /Missing required field/)
      end

      it "passes validation with all required fields" do
        expect do
          client.__send__(:validate_required_email_fields, {
                            from: "sender@example.com",
                            to: "recipient@example.com",
                            subject: "Test Subject"
                          })
        end.not_to raise_error
      end
    end

    describe "#extract_email_from_hash" do
      it "extracts email from symbol keys" do
        hash = {
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>",
          text: "Hello World"
        }

        email = client.__send__(:extract_email_from_hash, hash)
        expect(email.from).to eq("sender@example.com")
        expect(email.to).to eq("recipient@example.com")
        expect(email.subject).to eq("Test Subject")
        expect(email.html).to eq("<h1>Hello</h1>")
        expect(email.text).to eq("Hello World")
      end

      it "extracts email from string keys" do
        hash = {
          "from" => "sender@example.com",
          "to" => "recipient@example.com",
          "subject" => "Test Subject",
          "html" => "<h1>Hello</h1>",
          "text" => "Hello World"
        }

        email = client.__send__(:extract_email_from_hash, hash)
        expect(email.from).to eq("sender@example.com")
        expect(email.to).to eq("recipient@example.com")
        expect(email.subject).to eq("Test Subject")
        expect(email.html).to eq("<h1>Hello</h1>")
        expect(email.text).to eq("Hello World")
      end

      it "prefers symbol keys over string keys" do
        hash = {
          from: "symbol@example.com",
          "from" => "string@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>"
        }

        email = client.__send__(:extract_email_from_hash, hash)
        expect(email.from).to eq("symbol@example.com")
      end
    end
  end
end
