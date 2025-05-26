# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::RateLimitError do
  describe "#initialize" do
    it "creates error with default message" do
      error = described_class.new

      expect(error.status_code).to eq(429)
      expect(error.context[:error_type]).to eq("rate_limit_exceeded")
    end

    it "creates error with custom message" do
      error = described_class.new("Custom rate limit error")

      expect(error.message).to include("Custom rate limit error")
      expect(error.status_code).to eq(429)
    end
  end

  describe ".from_headers" do
    it "creates error from rate limit headers" do
      headers = {
        "X-RateLimit-Limit" => "100",
        "X-RateLimit-Remaining" => "0",
        "X-RateLimit-Reset" => "1640995200"
      }

      error = described_class.from_headers(headers)

      expect(error.message).to include("Rate limit exceeded")
      expect(error.status_code).to eq(429)
      expect(error.context[:limit]).to eq(100)
      expect(error.context[:remaining]).to eq(0)
      expect(error.context[:reset_time]).to eq(1_640_995_200)
    end

    it "creates error with missing headers" do
      headers = {}

      error = described_class.from_headers(headers)

      expect(error.message).to include("Rate limit exceeded")
      expect(error.status_code).to eq(429)
      expect(error.context[:limit]).to be_nil
      expect(error.context[:remaining]).to be_nil
      expect(error.context[:reset_at]).to be_nil
    end
  end

  describe "inheritance" do
    it "inherits from Poodle::Error" do
      error = described_class.new
      expect(error).to be_a(Poodle::Error)
    end

    it "can be rescued as RateLimitError" do
      expect do
        raise described_class, "Test rate limit error"
      rescue Poodle::RateLimitError => e
        expect(e).to be_a(described_class)
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end
end
