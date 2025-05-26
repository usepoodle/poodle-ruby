# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::Configuration do
  describe "#initialize" do
    it "sets default values" do
      ENV["POODLE_API_KEY"] = "test_key"
      config = described_class.new

      expect(config.api_key).to eq("test_key")
      expect(config.base_url).to eq("https://api.usepoodle.com")
      expect(config.timeout).to eq(30)
      expect(config.connect_timeout).to eq(10)
      expect(config.debug?).to be false

      ENV.delete("POODLE_API_KEY")
    end

    it "accepts custom values" do
      config = described_class.new(
        api_key: "custom_key",
        base_url: "https://custom.api.com",
        timeout: 60,
        connect_timeout: 20,
        debug: true
      )

      expect(config.api_key).to eq("custom_key")
      expect(config.base_url).to eq("https://custom.api.com")
      expect(config.timeout).to eq(60)
      expect(config.connect_timeout).to eq(20)
      expect(config.debug?).to be true
    end

    it "reads from environment variables" do
      ENV["POODLE_API_KEY"] = "env_key"
      ENV["POODLE_BASE_URL"] = "https://env.api.com"
      ENV["POODLE_TIMEOUT"] = "45"
      ENV["POODLE_CONNECT_TIMEOUT"] = "15"
      ENV["POODLE_DEBUG"] = "true"

      config = described_class.new

      expect(config.api_key).to eq("env_key")
      expect(config.base_url).to eq("https://env.api.com")
      expect(config.timeout).to eq(45)
      expect(config.connect_timeout).to eq(15)
      expect(config.debug?).to be true

      ENV.delete("POODLE_API_KEY")
      ENV.delete("POODLE_BASE_URL")
      ENV.delete("POODLE_TIMEOUT")
      ENV.delete("POODLE_CONNECT_TIMEOUT")
      ENV.delete("POODLE_DEBUG")
    end

    it "validates API key presence" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(ArgumentError, /API key is required/)

      expect { described_class.new(api_key: "") }
        .to raise_error(ArgumentError, /API key is required/)
    end

    it "validates base URL format" do
      expect { described_class.new(api_key: "test", base_url: "invalid-url") }
        .to raise_error(ArgumentError, /must be a valid HTTP or HTTPS URL/)

      expect { described_class.new(api_key: "test", base_url: "ftp://example.com") }
        .to raise_error(ArgumentError, /must be a valid HTTP or HTTPS URL/)
    end

    it "validates timeout values" do
      expect { described_class.new(api_key: "test", timeout: -1) }
        .to raise_error(ArgumentError, /timeout must be a positive integer/)

      expect { described_class.new(api_key: "test", connect_timeout: 0) }
        .to raise_error(ArgumentError, /connect_timeout must be a positive integer/)
    end
  end

  describe "#user_agent" do
    it "returns proper user agent string" do
      config = described_class.new(api_key: "test")
      expected = "poodle-ruby/#{Poodle::VERSION} (Ruby #{RUBY_VERSION})"
      expect(config.user_agent).to eq(expected)
    end
  end

  describe "#url_for" do
    let(:config) { described_class.new(api_key: "test", base_url: "https://api.example.com") }

    it "builds full URL for endpoint" do
      expect(config.url_for("send-email")).to eq("https://api.example.com/send-email")
    end

    it "handles leading slash in endpoint" do
      expect(config.url_for("/send-email")).to eq("https://api.example.com/send-email")
    end
  end

  describe "#debug?" do
    it "returns debug status" do
      config = described_class.new(api_key: "test", debug: true)
      expect(config.debug?).to be true

      config = described_class.new(api_key: "test", debug: false)
      expect(config.debug?).to be false
    end
  end
end
