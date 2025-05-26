# frozen_string_literal: true

require "spec_helper"

RSpec.describe Poodle::Email do
  describe "#initialize" do
    context "with valid parameters" do
      it "creates an email with HTML content" do
        email = described_class.new(
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>"
        )

        expect(email.from).to eq("sender@example.com")
        expect(email.to).to eq("recipient@example.com")
        expect(email.subject).to eq("Test Subject")
        expect(email.html).to eq("<h1>Hello</h1>")
        expect(email.text).to be_nil
      end

      it "creates an email with text content" do
        email = described_class.new(
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          text: "Hello World"
        )

        expect(email.from).to eq("sender@example.com")
        expect(email.to).to eq("recipient@example.com")
        expect(email.subject).to eq("Test Subject")
        expect(email.html).to be_nil
        expect(email.text).to eq("Hello World")
      end

      it "creates an email with both HTML and text content" do
        email = described_class.new(
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>",
          text: "Hello World"
        )

        expect(email.from).to eq("sender@example.com")
        expect(email.to).to eq("recipient@example.com")
        expect(email.subject).to eq("Test Subject")
        expect(email.html).to eq("<h1>Hello</h1>")
        expect(email.text).to eq("Hello World")
      end

      it "freezes the object after creation" do
        email = described_class.new(
          from: "sender@example.com",
          to: "recipient@example.com",
          subject: "Test Subject",
          html: "<h1>Hello</h1>"
        )

        expect(email).to be_frozen
      end
    end

    context "with invalid parameters" do
      it "raises ValidationError when from is missing" do
        expect do
          described_class.new(
            from: "",
            to: "recipient@example.com",
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /from/)
      end

      it "raises ValidationError when from is nil" do
        expect do
          described_class.new(
            from: nil,
            to: "recipient@example.com",
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /from/)
      end

      it "raises ValidationError when to is missing" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "",
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /to/)
      end

      it "raises ValidationError when to is nil" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: nil,
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /to/)
      end

      it "raises ValidationError when subject is missing" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: "",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /subject/)
      end

      it "raises ValidationError when subject is nil" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: nil,
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /subject/)
      end

      it "raises ValidationError when from email is invalid" do
        expect do
          described_class.new(
            from: "invalid-email",
            to: "recipient@example.com",
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /Invalid email address provided/)
      end

      it "raises ValidationError when to email is invalid" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "invalid-email",
            subject: "Test Subject",
            html: "<h1>Hello</h1>"
          )
        end.to raise_error(Poodle::ValidationError, /Invalid email address provided/)
      end

      it "raises ValidationError when no content is provided" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: "Test Subject"
          )
        end.to raise_error(Poodle::ValidationError, /content/)
      end

      it "raises ValidationError when both html and text are empty" do
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: "Test Subject",
            html: "",
            text: ""
          )
        end.to raise_error(Poodle::ValidationError, /content/)
      end

      it "raises ValidationError when HTML content is too large" do
        large_content = "a" * (Poodle::Configuration::MAX_CONTENT_SIZE + 1)
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: "Test Subject",
            html: large_content
          )
        end.to raise_error(Poodle::ValidationError, /Content size exceeds maximum allowed size/)
      end

      it "raises ValidationError when text content is too large" do
        large_content = "a" * (Poodle::Configuration::MAX_CONTENT_SIZE + 1)
        expect do
          described_class.new(
            from: "sender@example.com",
            to: "recipient@example.com",
            subject: "Test Subject",
            text: large_content
          )
        end.to raise_error(Poodle::ValidationError, /Content size exceeds maximum allowed size/)
      end
    end
  end

  describe "#to_h" do
    it "converts email to hash with HTML content" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      hash = email.to_h
      expect(hash).to eq({
                           from: "sender@example.com",
                           to: "recipient@example.com",
                           subject: "Test Subject",
                           html: "<h1>Hello</h1>"
                         })
    end

    it "converts email to hash with text content" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      hash = email.to_h
      expect(hash).to eq({
                           from: "sender@example.com",
                           to: "recipient@example.com",
                           subject: "Test Subject",
                           text: "Hello World"
                         })
    end

    it "converts email to hash with both HTML and text content" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: "Hello World"
      )

      hash = email.to_h
      expect(hash).to eq({
                           from: "sender@example.com",
                           to: "recipient@example.com",
                           subject: "Test Subject",
                           html: "<h1>Hello</h1>",
                           text: "Hello World"
                         })
    end
  end

  describe "#to_json" do
    it "converts email to JSON string" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      json = email.to_json
      parsed = JSON.parse(json)
      expect(parsed).to eq({
                             "from" => "sender@example.com",
                             "to" => "recipient@example.com",
                             "subject" => "Test Subject",
                             "html" => "<h1>Hello</h1>"
                           })
    end
  end

  describe "#html?" do
    it "returns true when HTML content is present" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(email.html?).to be true
    end

    it "returns false when HTML content is nil" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(email.html?).to be false
    end

    it "returns false when HTML content is empty" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "",
        text: "Hello World"
      )

      expect(email.html?).to be false
    end
  end

  describe "#text?" do
    it "returns true when text content is present" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(email.text?).to be true
    end

    it "returns false when text content is nil" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(email.text?).to be false
    end

    it "returns false when text content is empty" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: ""
      )

      expect(email.text?).to be false
    end
  end

  describe "#multipart?" do
    it "returns true when both HTML and text content are present" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: "Hello World"
      )

      expect(email.multipart?).to be true
    end

    it "returns false when only HTML content is present" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(email.multipart?).to be false
    end

    it "returns false when only text content is present" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(email.multipart?).to be false
    end
  end

  describe "#content_size" do
    it "returns size of HTML content only" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>"
      )

      expect(email.content_size).to eq("<h1>Hello</h1>".bytesize)
    end

    it "returns size of text content only" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        text: "Hello World"
      )

      expect(email.content_size).to eq("Hello World".bytesize)
    end

    it "returns combined size of HTML and text content" do
      email = described_class.new(
        from: "sender@example.com",
        to: "recipient@example.com",
        subject: "Test Subject",
        html: "<h1>Hello</h1>",
        text: "Hello World"
      )

      expected_size = "<h1>Hello</h1>".bytesize + "Hello World".bytesize
      expect(email.content_size).to eq(expected_size)
    end

    it "returns 0 when no content is provided (before validation)" do
      # This tests the method itself, validation would catch this in initialize
      email = described_class.allocate
      email.instance_variable_set(:@html, nil)
      email.instance_variable_set(:@text, nil)

      expect(email.content_size).to eq(0)
    end
  end
end
