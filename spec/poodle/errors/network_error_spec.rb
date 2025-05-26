# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::NetworkError do
  describe "#initialize" do
    it "creates error with default message" do
      error = described_class.new

      expect(error.message).to eq("Network error occurred")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({})
      expect(error.status_code).to be_nil
    end

    it "creates error with custom message" do
      error = described_class.new("Custom network error")

      expect(error.message).to eq("Custom network error")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({})
      expect(error.status_code).to be_nil
    end

    it "creates error with original error" do
      original = StandardError.new("Original error")
      error = described_class.new("Network error", original_error: original)

      expect(error.message).to eq("Network error")
      expect(error.original_error).to eq(original)
      expect(error.context).to eq({})
      expect(error.status_code).to be_nil
    end

    it "creates error with context" do
      context = { url: "https://api.example.com", timeout: 30 }
      error = described_class.new("Network error", context: context)

      expect(error.message).to eq("Network error")
      expect(error.original_error).to be_nil
      expect(error.context).to eq(context)
      expect(error.status_code).to be_nil
    end

    it "creates error with status code" do
      error = described_class.new("Network error", status_code: 500)

      expect(error.message).to eq("Network error")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({})
      expect(error.status_code).to eq(500)
    end

    it "creates error with all parameters" do
      original = StandardError.new("Original error")
      context = { url: "https://api.example.com" }
      error = described_class.new(
        "Network error",
        original_error: original,
        context: context,
        status_code: 502
      )

      expect(error.message).to eq("Network error")
      expect(error.original_error).to eq(original)
      expect(error.context).to eq(context)
      expect(error.status_code).to eq(502)
    end
  end

  describe ".connection_timeout" do
    it "creates error for connection timeout" do
      error = described_class.connection_timeout(30)

      expect(error.message).to eq("Connection timeout after 30 seconds")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ timeout: 30, error_type: "connection_timeout" })
      expect(error.status_code).to eq(408)
    end

    it "handles different timeout values" do
      error = described_class.connection_timeout(60)

      expect(error.message).to eq("Connection timeout after 60 seconds")
      expect(error.context[:timeout]).to eq(60)
    end

    it "handles zero timeout" do
      error = described_class.connection_timeout(0)

      expect(error.message).to eq("Connection timeout after 0 seconds")
      expect(error.context[:timeout]).to eq(0)
    end
  end

  describe ".connection_failed" do
    it "creates error for connection failure without original error" do
      url = "https://api.example.com"
      error = described_class.connection_failed(url)

      expect(error.message).to eq("Failed to connect to https://api.example.com")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ url: url, error_type: "connection_failed" })
      expect(error.status_code).to be_nil
    end

    it "creates error for connection failure with original error" do
      url = "https://api.example.com"
      original = StandardError.new("Connection refused")
      error = described_class.connection_failed(url, original_error: original)

      expect(error.message).to eq("Failed to connect to https://api.example.com")
      expect(error.original_error).to eq(original)
      expect(error.context).to eq({ url: url, error_type: "connection_failed" })
      expect(error.status_code).to be_nil
    end

    it "handles different URLs" do
      url = "http://localhost:3000"
      error = described_class.connection_failed(url)

      expect(error.message).to eq("Failed to connect to http://localhost:3000")
      expect(error.context[:url]).to eq(url)
    end
  end

  describe ".dns_resolution_failed" do
    it "creates error for DNS resolution failure" do
      host = "nonexistent.example.com"
      error = described_class.dns_resolution_failed(host)

      expect(error.message).to eq("DNS resolution failed for host: nonexistent.example.com")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ host: host, error_type: "dns_resolution_failed" })
      expect(error.status_code).to be_nil
    end

    it "handles different hostnames" do
      host = "api.invalid-domain.xyz"
      error = described_class.dns_resolution_failed(host)

      expect(error.message).to eq("DNS resolution failed for host: api.invalid-domain.xyz")
      expect(error.context[:host]).to eq(host)
    end

    it "handles IP addresses" do
      host = "192.168.1.999"
      error = described_class.dns_resolution_failed(host)

      expect(error.message).to eq("DNS resolution failed for host: 192.168.1.999")
      expect(error.context[:host]).to eq(host)
    end
  end

  describe ".ssl_error" do
    it "creates error for SSL/TLS error" do
      message = "certificate verify failed"
      error = described_class.ssl_error(message)

      expect(error.message).to eq("SSL/TLS error: certificate verify failed")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ error_type: "ssl_error" })
      expect(error.status_code).to be_nil
    end

    it "handles different SSL error messages" do
      message = "hostname does not match certificate"
      error = described_class.ssl_error(message)

      expect(error.message).to eq("SSL/TLS error: hostname does not match certificate")
      expect(error.context[:error_type]).to eq("ssl_error")
    end

    it "handles empty SSL error message" do
      error = described_class.ssl_error("")

      expect(error.message).to eq("SSL/TLS error: ")
      expect(error.context[:error_type]).to eq("ssl_error")
    end
  end

  describe ".http_error" do
    it "creates error for HTTP error with default message" do
      error = described_class.http_error(404)

      expect(error.message).to eq("HTTP error occurred with status code: 404")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ error_type: "http_error" })
      expect(error.status_code).to eq(404)
    end

    it "creates error for HTTP error with custom message" do
      error = described_class.http_error(500, "Internal server error")

      expect(error.message).to eq("Internal server error")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ error_type: "http_error" })
      expect(error.status_code).to eq(500)
    end

    it "creates error for HTTP error with empty message" do
      error = described_class.http_error(418, "")

      expect(error.message).to eq("HTTP error occurred with status code: 418")
      expect(error.context).to eq({ error_type: "http_error" })
      expect(error.status_code).to eq(418)
    end

    it "handles different status codes" do
      error = described_class.http_error(503, "Service unavailable")

      expect(error.message).to eq("Service unavailable")
      expect(error.status_code).to eq(503)
    end
  end

  describe ".malformed_response" do
    it "creates error for malformed response without response data" do
      error = described_class.malformed_response

      expect(error.message).to eq("Received malformed response from server")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ response: "", error_type: "malformed_response" })
      expect(error.status_code).to be_nil
    end

    it "creates error for malformed response with response data" do
      response = "invalid json response"
      error = described_class.malformed_response(response)

      expect(error.message).to eq("Received malformed response from server")
      expect(error.original_error).to be_nil
      expect(error.context).to eq({ response: response, error_type: "malformed_response" })
      expect(error.status_code).to be_nil
    end

    it "handles complex response data" do
      response = '{"incomplete": json'
      error = described_class.malformed_response(response)

      expect(error.message).to eq("Received malformed response from server")
      expect(error.context[:response]).to eq(response)
    end
  end

  describe "inheritance" do
    it "inherits from Poodle::Error" do
      error = described_class.new
      expect(error).to be_a(Poodle::Error)
    end

    it "inherits from StandardError" do
      error = described_class.new
      expect(error).to be_a(StandardError)
    end

    it "can be rescued as Poodle::Error" do
      expect do
        raise described_class, "Test network error"
      rescue Poodle::Error => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test network error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end

    it "can be rescued as NetworkError" do
      expect do
        raise described_class, "Test network error"
      rescue Poodle::NetworkError => e
        expect(e).to be_a(described_class)
        expect(e.message).to eq("Test network error")
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end

  describe "#original_error attribute" do
    it "provides read access to original error" do
      original = StandardError.new("Original error")
      error = described_class.new("Network error", original_error: original)

      expect(error.original_error).to eq(original)
      expect(error.original_error.message).to eq("Original error")
    end

    it "returns nil when no original error" do
      error = described_class.new("Network error")

      expect(error.original_error).to be_nil
    end
  end

  describe "#to_s" do
    it "includes status code when present" do
      error = described_class.new("Network error", status_code: 500)

      expect(error.to_s).to eq("Network error (Status: 500)")
    end

    it "includes context when present" do
      context = { url: "https://api.example.com", error_type: "connection_failed" }
      error = described_class.new("Network error", context: context)

      result = error.to_s
      expect(result).to include("Network error")
      expect(result).to include("Context:")
      expect(result).to include("https://api.example.com")
      expect(result).to include("connection_failed")
    end

    it "includes both status code and context when present" do
      context = { error_type: "http_error" }
      error = described_class.new("HTTP error", context: context, status_code: 404)

      result = error.to_s
      expect(result).to include("HTTP error")
      expect(result).to include("(Status: 404)")
      expect(result).to include("Context:")
      expect(result).to include("http_error")
    end
  end
end
