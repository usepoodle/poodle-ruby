# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::PaymentError do
  describe "#initialize" do
    it "creates error with default message" do
      error = described_class.new

      expect(error.status_code).to eq(402)
      expect(error.context[:upgrade_url]).to be_nil
    end

    it "creates error with custom message" do
      error = described_class.new("Custom payment error")

      expect(error.message).to include("Custom payment error")
      expect(error.status_code).to eq(402)
    end
  end

  describe ".subscription_expired" do
    it "creates error for expired subscription" do
      error = described_class.subscription_expired

      expect(error.message).to include("Subscription expired")
      expect(error.status_code).to eq(402)
      expect(error.context[:error_type]).to eq("subscription_expired")
    end
  end

  describe ".trial_limit_reached" do
    it "creates error for trial limit" do
      error = described_class.trial_limit_reached

      expect(error.message).to include("Trial limit")
      expect(error.status_code).to eq(402)
      expect(error.context[:error_type]).to eq("trial_limit_reached")
    end
  end

  describe ".monthly_limit_exceeded" do
    it "creates error for monthly limit" do
      error = described_class.monthly_limit_exceeded

      expect(error.message).to include("Monthly email limit")
      expect(error.status_code).to eq(402)
      expect(error.context[:error_type]).to eq("monthly_limit_exceeded")
    end
  end

  describe "inheritance" do
    it "inherits from Poodle::Error" do
      error = described_class.new
      expect(error).to be_a(Poodle::Error)
    end

    it "can be rescued as PaymentError" do
      expect do
        raise described_class, "Test payment error"
      rescue Poodle::PaymentError => e
        expect(e).to be_a(described_class)
        raise "rescued successfully"
      end.to raise_error("rescued successfully")
    end
  end
end
