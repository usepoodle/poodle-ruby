# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::HttpClient do
  let(:config) { Poodle::Configuration.new(api_key: "test_api_key") }
  let(:mock_connection) { instance_double(Faraday::Connection) }
  let(:mock_response) { instance_double(Faraday::Response) }

  before do
    allow(Faraday).to receive(:new).and_return(mock_connection)
    allow(mock_connection).to receive(:request)
    allow(mock_connection).to receive(:response)
    allow(mock_connection).to receive(:adapter)
    allow(mock_connection).to receive(:options).and_return(double(timeout: nil, open_timeout: nil))
    allow(mock_connection).to receive(:headers).and_return({})
  end

  describe "#initialize" do
    it "creates http client with configuration" do
      http_client = described_class.new(config)
      expect(http_client.config).to eq(config)
    end

    it "builds faraday connection" do
      described_class.new(config)
      expect(Faraday).to have_received(:new)
    end
  end

  let(:http_client) { described_class.new(config) }

  describe "#post" do
    let(:endpoint) { "v1/send-email" }
    let(:data) { { from: "test@example.com", to: "recipient@example.com" } }
    let(:headers) { { "Custom-Header" => "value" } }

    before do
      allow(config).to receive(:url_for).with(endpoint).and_return("https://api.example.com/v1/send-email")
      allow(config).to receive(:debug?).and_return(false)
      allow(mock_connection).to receive(:post).and_return(mock_response)
      allow(mock_response).to receive(:status).and_return(200)
      allow(mock_response).to receive(:body).and_return({ "success" => true })
    end

    it "sends POST request with data" do
      expect(mock_connection).to receive(:post).with("https://api.example.com/v1/send-email")

      result = http_client.post(endpoint, data, headers)
      expect(result).to eq({ "success" => true })
    end

    it "handles successful response" do
      result = http_client.post(endpoint, data)
      expect(result).to eq({ "success" => true })
    end

    it "handles empty response body" do
      allow(mock_response).to receive(:body).and_return(nil)

      result = http_client.post(endpoint, data)
      expect(result).to eq({})
    end
  end

  describe "#get" do
    let(:endpoint) { "v1/status" }
    let(:params) { { id: "123" } }

    before do
      allow(config).to receive(:url_for).with(endpoint).and_return("https://api.example.com/v1/status")
      allow(config).to receive(:debug?).and_return(false)
      allow(mock_connection).to receive(:get).and_return(mock_response)
      allow(mock_response).to receive(:status).and_return(200)
      allow(mock_response).to receive(:body).and_return({ "status" => "active" })
    end

    it "sends GET request with params" do
      expect(mock_connection).to receive(:get).with("https://api.example.com/v1/status")

      result = http_client.get(endpoint, params)
      expect(result).to eq({ "status" => "active" })
    end
  end

  describe "error handling" do
    let(:endpoint) { "v1/send-email" }
    let(:data) { {} }

    before do
      allow(config).to receive(:url_for).with(endpoint).and_return("https://api.example.com/v1/send-email")
      allow(config).to receive(:debug?).and_return(false)
      allow(mock_connection).to receive(:post).and_return(mock_response)
    end

    context "when response is 400 (validation error)" do
      before do
        allow(mock_response).to receive(:status).and_return(400)
        allow(mock_response).to receive(:body).and_return({
                                                            "message" => "Validation failed",
                                                            "errors" => { "email" => ["Invalid format"] }
                                                          })
      end

      it "raises ValidationError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ValidationError, /Validation failed/)
      end
    end

    context "when response is 401 (authentication error)" do
      before do
        allow(mock_response).to receive(:status).and_return(401)
        allow(mock_response).to receive(:body).and_return({ "message" => "Invalid API key" })
      end

      it "raises AuthenticationError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::AuthenticationError)
      end
    end

    context "when response is 402 (payment error)" do
      before do
        allow(mock_response).to receive(:status).and_return(402)
      end

      it "raises PaymentError for subscription expired" do
        allow(mock_response).to receive(:body).and_return({ "message" => "Subscription has expired" })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::PaymentError)
      end

      it "raises PaymentError for trial limit" do
        allow(mock_response).to receive(:body).and_return({ "message" => "Trial limit reached" })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::PaymentError)
      end

      it "raises PaymentError for monthly limit" do
        allow(mock_response).to receive(:body).and_return({ "message" => "Monthly limit exceeded" })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::PaymentError)
      end

      it "raises generic PaymentError for other payment issues" do
        allow(mock_response).to receive(:body).and_return({ "message" => "Payment required" })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::PaymentError, /Payment required/)
      end
    end

    context "when response is 403 (forbidden error)" do
      before do
        allow(mock_response).to receive(:status).and_return(403)
      end

      it "raises ForbiddenError for insufficient permissions" do
        allow(mock_response).to receive(:body).and_return({ "message" => "Access denied" })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ForbiddenError)
      end

      it "raises ForbiddenError for account suspended" do
        allow(mock_response).to receive(:body).and_return({
                                                            "message" => "Account suspended",
                                                            "reason" => "abuse",
                                                            "rate" => "high"
                                                          })

        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ForbiddenError)
      end
    end

    context "when response is 422 (unprocessable entity)" do
      before do
        allow(mock_response).to receive(:status).and_return(422)
        allow(mock_response).to receive(:body).and_return({
                                                            "message" => "Unprocessable entity",
                                                            "errors" => { "content" => ["Required"] }
                                                          })
      end

      it "raises ValidationError with 422 status code" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ValidationError)

        begin
          http_client.post(endpoint, data)
        rescue Poodle::ValidationError => e
          expect(e.status_code).to eq(422)
        end
      end
    end

    context "when response is 429 (rate limit)" do
      before do
        allow(mock_response).to receive(:status).and_return(429)
        allow(mock_response).to receive(:headers).and_return({
                                                               "X-RateLimit-Limit" => "100",
                                                               "X-RateLimit-Remaining" => "0",
                                                               "X-RateLimit-Reset" => "1640995200"
                                                             })
      end

      it "raises RateLimitError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::RateLimitError)
      end
    end

    context "when response is 500 (server error)" do
      before do
        allow(mock_response).to receive(:status).and_return(500)
        allow(mock_response).to receive(:body).and_return({ "message" => "Internal server error" })
      end

      it "raises ServerError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ServerError)
      end
    end

    context "when response is 502 (bad gateway)" do
      before do
        allow(mock_response).to receive(:status).and_return(502)
        allow(mock_response).to receive(:body).and_return({ "message" => "Bad gateway" })
      end

      it "raises ServerError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ServerError)
      end
    end

    context "when response is 503 (service unavailable)" do
      before do
        allow(mock_response).to receive(:status).and_return(503)
        allow(mock_response).to receive(:body).and_return({ "message" => "Service unavailable" })
      end

      it "raises ServerError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ServerError)
      end
    end

    context "when response is 504 (gateway timeout)" do
      before do
        allow(mock_response).to receive(:status).and_return(504)
        allow(mock_response).to receive(:body).and_return({ "message" => "Gateway timeout" })
      end

      it "raises ServerError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::ServerError)
      end
    end

    context "when response is unknown error code" do
      before do
        allow(mock_response).to receive(:status).and_return(418)
        allow(mock_response).to receive(:body).and_return({ "message" => "I'm a teapot" })
      end

      it "raises NetworkError" do
        expect do
          http_client.post(endpoint, data)
        end.to raise_error(Poodle::NetworkError)
      end
    end
  end

  describe "network error handling" do
    let(:endpoint) { "v1/send-email" }
    let(:data) { {} }

    before do
      allow(config).to receive(:url_for).with(endpoint).and_return("https://api.example.com/v1/send-email")
      allow(config).to receive(:debug?).and_return(false)
      allow(config).to receive(:timeout).and_return(30)
      allow(config).to receive(:base_url).and_return("https://api.example.com")
    end

    it "handles timeout errors" do
      allow(mock_connection).to receive(:post).and_raise(Faraday::TimeoutError.new("timeout"))

      expect do
        http_client.post(endpoint, data)
      end.to raise_error(Poodle::NetworkError)
    end

    it "handles SSL connection errors" do
      ssl_error = Faraday::ConnectionFailed.new("SSL certificate verification failed")
      allow(mock_connection).to receive(:post).and_raise(ssl_error)

      expect do
        http_client.post(endpoint, data)
      end.to raise_error(Poodle::NetworkError)
    end

    it "handles DNS resolution errors" do
      dns_error = Faraday::ConnectionFailed.new("Failed to resolve hostname")
      allow(mock_connection).to receive(:post).and_raise(dns_error)

      expect do
        http_client.post(endpoint, data)
      end.to raise_error(Poodle::NetworkError)
    end

    it "handles generic connection errors" do
      connection_error = Faraday::ConnectionFailed.new("Connection refused")
      allow(mock_connection).to receive(:post).and_raise(connection_error)

      expect do
        http_client.post(endpoint, data)
      end.to raise_error(Poodle::NetworkError)
    end

    it "handles generic Faraday errors" do
      faraday_error = Faraday::Error.new("Generic Faraday error")
      allow(mock_connection).to receive(:post).and_raise(faraday_error)

      expect do
        http_client.post(endpoint, data)
      end.to raise_error(Poodle::NetworkError)
    end
  end

  describe "debugging" do
    let(:endpoint) { "v1/send-email" }
    let(:data) { { test: "data" } }

    before do
      allow(config).to receive(:url_for).with(endpoint).and_return("https://api.example.com/v1/send-email")
      allow(config).to receive(:debug?).and_return(true)
      allow(mock_connection).to receive(:post).and_return(mock_response)
      allow(mock_response).to receive(:status).and_return(200)
      allow(mock_response).to receive(:body).and_return({ "success" => true })
    end

    it "logs request when debug is enabled" do
      expect { http_client.post(endpoint, data) }.to output(/\[Poodle\] POST/).to_stdout
    end

    it "logs response when debug is enabled" do
      expect { http_client.post(endpoint, data) }.to output(/\[Poodle\] Response: 200/).to_stdout
    end

    it "logs request data when debug is enabled" do
      expect { http_client.post(endpoint, data) }.to output(/\[Poodle\] Request:/).to_stdout
    end

    it "logs response body when debug is enabled" do
      expect { http_client.post(endpoint, data) }.to output(/\[Poodle\] Body:/).to_stdout
    end
  end

  describe "private methods" do
    let(:http_client_with_access) do
      Class.new(described_class) do
        def public_extract_error_message(response)
          extract_error_message(response)
        end

        def public_extract_validation_errors(body)
          extract_validation_errors(body)
        end

        def public_success_response?(response)
          success_response?(response)
        end
      end.new(config)
    end

    describe "#extract_error_message" do
      it "extracts message from response body" do
        response = double(body: { "message" => "Test error" }, status: 400)
        message = http_client_with_access.public_extract_error_message(response)
        expect(message).to eq("Test error")
      end

      it "extracts error from response body when message is missing" do
        response = double(body: { "error" => "Test error" }, status: 400)
        message = http_client_with_access.public_extract_error_message(response)
        expect(message).to eq("Test error")
      end

      it "returns default message when body has no message or error" do
        response = double(body: { "data" => "something" }, status: 400)
        message = http_client_with_access.public_extract_error_message(response)
        expect(message).to eq("HTTP 400 error")
      end

      it "returns default message when body is not a hash" do
        response = double(body: "string body", status: 500)
        message = http_client_with_access.public_extract_error_message(response)
        expect(message).to eq("HTTP 500 error")
      end

      it "returns default message when body is nil" do
        response = double(body: nil, status: 404)
        message = http_client_with_access.public_extract_error_message(response)
        expect(message).to eq("HTTP 404 error")
      end
    end

    describe "#extract_validation_errors" do
      it "extracts errors from body" do
        body = { "errors" => { "email" => "Invalid", "name" => "Required" } }
        errors = http_client_with_access.public_extract_validation_errors(body)
        expect(errors).to eq({ "email" => ["Invalid"], "name" => ["Required"] })
      end

      it "extracts validation_errors from body" do
        body = { "validation_errors" => { "email" => ["Invalid format"] } }
        errors = http_client_with_access.public_extract_validation_errors(body)
        expect(errors).to eq({ "email" => ["Invalid format"] })
      end

      it "converts string values to arrays" do
        body = { "errors" => { "email" => "Invalid format" } }
        errors = http_client_with_access.public_extract_validation_errors(body)
        expect(errors).to eq({ "email" => ["Invalid format"] })
      end

      it "returns empty hash when body is not a hash" do
        errors = http_client_with_access.public_extract_validation_errors("string")
        expect(errors).to eq({})
      end

      it "returns empty hash when errors is not a hash" do
        body = { "errors" => "string errors" }
        errors = http_client_with_access.public_extract_validation_errors(body)
        expect(errors).to eq({})
      end

      it "returns empty hash when no errors field" do
        body = { "message" => "Error occurred" }
        errors = http_client_with_access.public_extract_validation_errors(body)
        expect(errors).to eq({})
      end
    end

    describe "#success_response?" do
      it "returns true for 200 status" do
        response = double(status: 200)
        expect(http_client_with_access.public_success_response?(response)).to be true
      end

      it "returns true for 201 status" do
        response = double(status: 201)
        expect(http_client_with_access.public_success_response?(response)).to be true
      end

      it "returns true for 299 status" do
        response = double(status: 299)
        expect(http_client_with_access.public_success_response?(response)).to be true
      end

      it "returns false for 199 status" do
        response = double(status: 199)
        expect(http_client_with_access.public_success_response?(response)).to be false
      end

      it "returns false for 300 status" do
        response = double(status: 300)
        expect(http_client_with_access.public_success_response?(response)).to be false
      end

      it "returns false for 400 status" do
        response = double(status: 400)
        expect(http_client_with_access.public_success_response?(response)).to be false
      end

      it "returns false for 500 status" do
        response = double(status: 500)
        expect(http_client_with_access.public_success_response?(response)).to be false
      end
    end
  end

  describe "unsupported HTTP method" do
    it "raises ArgumentError for unsupported method" do
      allow(config).to receive(:url_for).and_return("https://api.example.com/test")
      allow(config).to receive(:debug?).and_return(false)

      expect do
        http_client.send(:perform_request, :patch, "https://api.example.com/test", {}, {})
      end.to raise_error(ArgumentError, /Unsupported HTTP method: patch/)
    end
  end
end
