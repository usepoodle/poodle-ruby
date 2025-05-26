#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "poodle"

# Basic usage example for the Poodle Ruby SDK

# Set your API key (you can also use environment variables)
# ENV["POODLE_API_KEY"] = "your_api_key_here"

begin
  # Initialize the client
  client = Poodle::Client.new(api_key: "your_api_key_here")

  # Send a simple HTML email
  response = client.send(
    from: "sender@example.com",
    to: "recipient@example.com",
    subject: "Hello from Poodle Ruby SDK!",
    html: "<h1>Hello World!</h1><p>This email was sent using the Poodle Ruby SDK.</p>"
  )

  if response.success?
    puts "✅ Email sent successfully!"
  else
    puts "❌ Failed to send email"
  end
  puts "Message: #{response.message}"

  # Send a text-only email
  text_response = client.send_text(
    from: "sender@example.com",
    to: "recipient@example.com",
    subject: "Plain text email",
    text: "This is a plain text email sent using the Poodle Ruby SDK."
  )

  puts "\nText email result: #{text_response.success? ? 'Success' : 'Failed'}"

  # Send an HTML-only email
  html_response = client.send_html(
    from: "sender@example.com",
    to: "recipient@example.com",
    subject: "HTML email",
    html: "<h2>Newsletter</h2><p>This is an HTML email with <strong>formatting</strong>.</p>"
  )

  puts "HTML email result: #{html_response.success? ? 'Success' : 'Failed'}"
rescue Poodle::ValidationError => e
  puts "❌ Validation error: #{e.message}"
  puts "Errors: #{e.errors}"
rescue Poodle::AuthenticationError => e
  puts "❌ Authentication error: #{e.message}"
  puts "Please check your API key"
rescue Poodle::RateLimitError => e
  puts "❌ Rate limit exceeded: #{e.message}"
  puts "Retry after: #{e.retry_after} seconds" if e.retry_after
rescue Poodle::Error => e
  puts "❌ Poodle error: #{e.message}"
  puts "Status code: #{e.status_code}" if e.status_code
rescue StandardError => e
  puts "❌ Unexpected error: #{e.message}"
end
