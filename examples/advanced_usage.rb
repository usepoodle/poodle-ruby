#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "poodle"

# Advanced usage example for the Poodle Ruby SDK

# Example 1: Using configuration object
puts "=== Example 1: Configuration Object ==="

config = Poodle::Configuration.new(
  api_key: "your_api_key_here",
  base_url: "https://api.usepoodle.com",
  timeout: 60,
  debug: true
)

client = Poodle::Client.new(config)
puts "Client initialized with custom configuration"
puts "User-Agent: #{config.user_agent}"
puts "Base URL: #{config.base_url}"

# Example 2: Using Email objects
puts "\n=== Example 2: Email Objects ==="

begin
  # Create an Email object
  email = Poodle::Email.new(
    from: "newsletter@example.com",
    to: "subscriber@example.com",
    subject: "Weekly Newsletter - #{Date.today}",
    html: <<~HTML,
      <html>
        <body>
          <h1>Weekly Newsletter</h1>
          <p>Welcome to our weekly newsletter!</p>
          <ul>
            <li>Feature 1: New dashboard</li>
            <li>Feature 2: Improved performance</li>
            <li>Feature 3: Bug fixes</li>
          </ul>
          <p>Best regards,<br>The Team</p>
        </body>
      </html>
    HTML
    text: <<~TEXT
      Weekly Newsletter - #{Date.today}

      Welcome to our weekly newsletter!

      - Feature 1: New dashboard
      - Feature 2: Improved performance
      - Feature 3: Bug fixes

      Best regards,
      The Team
    TEXT
  )

  puts "Email object created:"
  puts "- From: #{email.from}"
  puts "- To: #{email.to}"
  puts "- Subject: #{email.subject}"
  puts "- Has HTML: #{email.html?}"
  puts "- Has Text: #{email.text?}"
  puts "- Is Multipart: #{email.multipart?}"
  puts "- Content Size: #{email.content_size} bytes"

  # Send the email object
  response = client.send_email(email)
  puts "Email sent: #{response.success?}"
rescue Poodle::ValidationError => e
  puts "Validation failed: #{e.message}"
  e.errors.each do |field, messages|
    puts "  #{field}: #{messages.join(', ')}"
  end
end

# Example 3: Environment variables
puts "\n=== Example 3: Environment Variables ==="

# Set environment variables
ENV["POODLE_API_KEY"] = "your_api_key_here"
ENV["POODLE_DEBUG"] = "true"
ENV["POODLE_TIMEOUT"] = "45"

# Create client using environment variables
env_client = Poodle::Client.new
puts "Client created using environment variables"
puts "Debug mode: #{env_client.config.debug?}"
puts "Timeout: #{env_client.config.timeout} seconds"

# Example 4: Multiple content types
puts "\n=== Example 4: Multiple Content Types ==="

begin
  # Send email with both HTML and text content
  multipart_response = client.send(
    from: "newsletter@example.com",
    to: "subscriber@example.com",
    subject: "Weekly Newsletter",
    html: "<h1>Newsletter</h1><p>This week's updates...</p>",
    text: "Newsletter\n\nThis week's updates..."
  )

  puts "Multipart email sent: #{multipart_response.success?}"
rescue Poodle::Error => e
  puts "Multipart email error: #{e.message}"
end

# Example 5: Comprehensive error handling
puts "\n=== Example 5: Error Handling ==="

def send_email_with_retry(client, email_data, max_retries: 3)
  retries = 0

  begin
    response = client.send(email_data)
    puts "Email sent successfully: #{response.message}"
    response
  rescue Poodle::RateLimitError => e
    handle_rate_limit_error(e, retries, max_retries)
    retries += 1
    retry
  rescue Poodle::NetworkError => e
    handle_network_error(e, retries, max_retries)
    retries += 1
    retry
  rescue Poodle::ServerError => e
    handle_server_error(e, retries, max_retries)
    retries += 1
    retry
  rescue Poodle::ValidationError => e
    handle_validation_error(e)
  rescue Poodle::AuthenticationError => e
    handle_authentication_error(e)
  rescue Poodle::PaymentError => e
    handle_payment_error(e)
  rescue Poodle::ForbiddenError => e
    handle_forbidden_error(e)
  end
end

def handle_rate_limit_error(error, retries, max_retries)
  if retries < max_retries && error.retry_after
    puts "Rate limited. Retrying in #{error.retry_after} seconds... (attempt #{retries + 1}/#{max_retries})"
    sleep(error.retry_after)
  else
    puts "Rate limit exceeded. Max retries reached."
    raise error
  end
end

def handle_network_error(error, retries, max_retries)
  if retries < max_retries
    puts "Network error. Retrying... (attempt #{retries + 1}/#{max_retries})"
    sleep(2**(retries + 1)) # Exponential backoff
  else
    puts "Network error. Max retries reached."
    raise error
  end
end

def handle_server_error(error, retries, max_retries)
  if retries < max_retries
    puts "Server error. Retrying... (attempt #{retries + 1}/#{max_retries})"
    sleep(2**(retries + 1))
  else
    puts "Server error. Max retries reached."
    raise error
  end
end

def handle_validation_error(error)
  puts "Validation error (not retryable): #{error.message}"
  puts "Errors: #{error.errors}"
  raise error
end

def handle_authentication_error(error)
  puts "Authentication error (not retryable): #{error.message}"
  raise error
end

def handle_payment_error(error)
  puts "Payment required: #{error.message}"
  puts "Upgrade URL: #{error.upgrade_url}" if error.upgrade_url
  raise error
end

def handle_forbidden_error(error)
  puts "Access forbidden: #{error.message}"
  puts "Reason: #{error.reason}" if error.reason
  raise error
end

# Test the retry mechanism
email_data = {
  from: "retry@example.com",
  to: "test@example.com",
  subject: "Retry Test",
  html: "<p>Testing retry mechanism</p>"
}

begin
  send_email_with_retry(client, email_data)
rescue Poodle::Error => e
  puts "Final error: #{e.message}"
end

# Example 6: Batch sending (conceptual)
puts "\n=== Example 6: Batch Sending ==="

recipients = [
  "user1@example.com",
  "user2@example.com",
  "user3@example.com"
]

successful_sends = 0
failed_sends = 0

recipients.each_with_index do |recipient, index|
  response = client.send(
    from: "batch@example.com",
    to: recipient,
    subject: "Batch Email #{index + 1}",
    html: "<p>Hello #{recipient}! This is batch email ##{index + 1}</p>"
  )

  if response.success?
    successful_sends += 1
    puts "✅ Sent to #{recipient}"
  else
    failed_sends += 1
    puts "❌ Failed to send to #{recipient}: #{response.message}"
  end

  # Rate limiting: wait between sends
  sleep(0.1)
rescue Poodle::Error => e
  failed_sends += 1
  puts "❌ Error sending to #{recipient}: #{e.message}"
end

puts "\nBatch sending complete:"
puts "Successful: #{successful_sends}"
puts "Failed: #{failed_sends}"
puts "Total: #{recipients.length}"

# Clean up environment variables
ENV.delete("POODLE_API_KEY")
ENV.delete("POODLE_DEBUG")
ENV.delete("POODLE_TIMEOUT")
