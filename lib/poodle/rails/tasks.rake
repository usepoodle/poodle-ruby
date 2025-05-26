# frozen_string_literal: true

namespace :poodle do
  desc "Check Poodle configuration"
  task config: :environment do
    if Poodle::Rails.configured?
      config = Poodle::Rails.configuration
      puts "✅ Poodle is configured"
      puts "   API Key: #{config.api_key ? "***#{config.api_key[-4..]}" : 'Not set'}"
      puts "   Base URL: #{config.base_url}"
      puts "   Timeout: #{config.timeout}s"
      puts "   Debug: #{config.debug?}"
    else
      puts "❌ Poodle is not configured"
      puts "   Set POODLE_API_KEY environment variable or configure in Rails credentials"
    end
  end

  desc "Test Poodle connection"
  task test: :environment do
    unless Poodle::Rails.configured?
      puts "❌ Poodle is not configured. Run 'rake poodle:config' to check configuration."
      exit 1
    end

    begin
      client = Poodle::Rails.client
      puts "✅ Poodle client created successfully"
      puts "   SDK Version: #{Poodle::VERSION}"
      puts "   User Agent: #{client.config.user_agent}"
    rescue StandardError => e
      puts "❌ Failed to create Poodle client: #{e.message}"
      exit 1
    end
  end

  desc "Send a test email"
  task :send_test, %i[to from] => :environment do |_t, args|
    unless Poodle::Rails.configured?
      puts "❌ Poodle is not configured. Run 'rake poodle:config' to check configuration."
      exit 1
    end

    to_email = args[:to] || ENV.fetch("POODLE_TEST_TO", nil)
    from_email = args[:from] || ENV["POODLE_TEST_FROM"] || "test@example.com"

    unless to_email
      puts "❌ Please provide a recipient email address:"
      puts "   rake poodle:send_test[recipient@example.com]"
      puts "   or set POODLE_TEST_TO environment variable"
      exit 1
    end

    begin
      client = Poodle::Rails.client
      response = client.send(
        from: from_email,
        to: to_email,
        subject: "Test Email from Poodle Ruby SDK",
        html: "<h1>Test Email</h1><p>This is a test email sent from the Poodle Ruby SDK in a Rails application.</p>",
        text: "Test Email\n\nThis is a test email sent from the Poodle Ruby SDK in a Rails application."
      )

      if response.success?
        puts "✅ Test email sent successfully!"
        puts "   From: #{from_email}"
        puts "   To: #{to_email}"
        puts "   Message: #{response.message}"
      else
        puts "❌ Failed to send test email: #{response.message}"
        exit 1
      end
    rescue StandardError => e
      puts "❌ Error sending test email: #{e.message}"
      puts "   #{e.class.name}"
      exit 1
    end
  end

  desc "Generate Poodle initializer"
  task install: :environment do
    initializer_path = Rails.root.join("config", "initializers", "poodle.rb")

    if File.exist?(initializer_path)
      puts "⚠️  Poodle initializer already exists at #{initializer_path}"
      puts "   Remove it first if you want to regenerate it."
      exit 1
    end

    initializer_content = <<~RUBY
      # frozen_string_literal: true

      # Poodle email sending configuration
      Poodle::Rails.configure do |config|
        # API key from Rails credentials or environment variable
        config.api_key = Rails.application.credentials.poodle_api_key || ENV['POODLE_API_KEY']

        # Optional: Override base URL (defaults to https://api.usepoodle.com)
        # config.base_url = ENV['POODLE_BASE_URL']

        # Optional: Set timeout (defaults to 30 seconds)
        # config.timeout = 30

        # Optional: Enable debug mode in development
        config.debug = Rails.env.development?
      end
    RUBY

    File.write(initializer_path, initializer_content)
    puts "✅ Created Poodle initializer at #{initializer_path}"
    puts "   Don't forget to set your API key in Rails credentials or environment variables!"
  end
end
