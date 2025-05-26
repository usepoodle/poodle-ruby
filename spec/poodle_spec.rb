# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle do
  it "has a version number" do
    expect(Poodle::VERSION).not_to be nil
    expect(Poodle::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".new" do
    it "creates a new client instance" do
      ENV["POODLE_API_KEY"] = "test_key"
      client = Poodle.new
      expect(client).to be_a(Poodle::Client)
      ENV.delete("POODLE_API_KEY")
    end
  end

  describe ".version" do
    it "returns the version" do
      expect(Poodle.version).to eq(Poodle::VERSION)
    end
  end
end
