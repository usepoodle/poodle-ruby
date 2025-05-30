# Poodle Ruby SDK

[![Gem Version](https://badge.fury.io/rb/poodle-ruby.svg)](https://rubygems.org/gems/poodle-ruby)
[![Build Status](https://github.com/usepoodle/poodle-ruby/workflows/CI/badge.svg)](https://github.com/usepoodle/poodle-ruby/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/usepoodle/poodle-ruby/blob/main/LICENSE)

Ruby SDK for the Poodle's email sending API.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)
- [Error Types](#error-types)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)

## Features

- 🚀 **Simple API** - Send emails with just a few lines of code
- 🔒 **Type Safe** - Comprehensive validation and error handling
- 🌐 **Environment Support** - Easy configuration via environment variables
- 📝 **Rich Content** - Support for HTML, plain text, and multipart emails
- 🔄 **Retry Logic** - Built-in support for handling rate limits and network issues
- 🧪 **Test Support** - Comprehensive testing utilities and mocks
- 📚 **Well Documented** - Comprehensive documentation and examples
- 🎯 **Ruby 3.0+** - Modern Ruby support with keyword arguments

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'poodle-ruby'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install poodle-ruby
```

## Quick Start

```ruby
require 'poodle'

# Initialize the client
client = Poodle::Client.new(api_key: 'your_api_key')

# Send an email
response = client.send(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Hello from Poodle!',
  html: '<h1>Hello World!</h1><p>This email was sent using Poodle.</p>'
)

if response.success?
  puts "Email sent successfully!"
else
  puts "Failed to send email: #{response.message}"
end
```

## Configuration

### API Key

Set your API key in one of these ways:

```ruby
# 1. Pass directly to client
client = Poodle::Client.new(api_key: 'your_api_key')

# 2. Use environment variable
ENV['POODLE_API_KEY'] = 'your_api_key'
client = Poodle::Client.new

# 3. Use configuration object
config = Poodle::Configuration.new(
  api_key: 'your_api_key',
  timeout: 30,
  debug: true
)
client = Poodle::Client.new(config)
```

### Environment Variables

| Variable                 | Description                   | Default                     |
| ------------------------ | ----------------------------- | --------------------------- |
| `POODLE_API_KEY`         | Your Poodle API key           | Required                    |
| `POODLE_BASE_URL`        | API base URL                  | `https://api.usepoodle.com` |
| `POODLE_TIMEOUT`         | Request timeout in seconds    | `30`                        |
| `POODLE_CONNECT_TIMEOUT` | Connection timeout in seconds | `10`                        |
| `POODLE_DEBUG`           | Enable debug logging          | `false`                     |

## Usage Examples

### Basic Email Sending

```ruby
# HTML email
response = client.send_html(
  from: 'newsletter@example.com',
  to: 'subscriber@example.com',
  subject: 'Weekly Newsletter',
  html: '<h1>Newsletter</h1><p>Your weekly update...</p>'
)

# Plain text email
response = client.send_text(
  from: 'notifications@example.com',
  to: 'user@example.com',
  subject: 'Account Update',
  text: 'Your account has been updated successfully.'
)

# Multipart email (HTML + Text)
response = client.send(
  from: 'support@example.com',
  to: 'customer@example.com',
  subject: 'Welcome!',
  html: '<h1>Welcome!</h1><p>Thanks for joining us.</p>',
  text: 'Welcome! Thanks for joining us.'
)
```

### Using Email Objects

```ruby
# Create an Email object for reusability and validation
email = Poodle::Email.new(
  from: 'sender@example.com',
  to: 'recipient@example.com',
  subject: 'Important Update',
  html: '<h1>Update</h1><p>Please read this important update.</p>',
  text: 'Update: Please read this important update.'
)

# Check email properties
puts "Multipart email: #{email.multipart?}"
puts "Content size: #{email.content_size} bytes"

# Send the email
response = client.send_email(email)
```

### Multipart Emails (HTML + Text)

```ruby
# Send emails with both HTML and text content for maximum compatibility
response = client.send(
  from: 'newsletter@example.com',
  to: 'subscriber@example.com',
  subject: 'Weekly Newsletter',
  html: '<h1>Newsletter</h1><p>This week\'s updates...</p>',
  text: 'Newsletter\n\nThis week\'s updates...'
)
```

### Rails Integration

The Poodle SDK provides seamless Rails integration with automatic configuration and helpful rake tasks.

#### Installation

Add to your Rails application's Gemfile:

```ruby
gem 'poodle-ruby'
```

#### Configuration

Create an initializer or let Poodle auto-configure:

```ruby
# config/initializers/poodle.rb
Poodle::Rails.configure do |config|
  config.api_key = Rails.application.credentials.poodle_api_key
  config.debug = Rails.env.development?
end
```

Or use environment variables:

```bash
# .env or environment
POODLE_API_KEY=your_api_key_here
```

#### Usage in Controllers

```ruby
class NotificationController < ApplicationController
  def send_welcome_email
    response = Poodle::Rails.client.send(
      from: "welcome@example.com",
      to: params[:email],
      subject: "Welcome!",
      html: render_to_string("welcome_email")
    )

    if response.success?
      render json: { status: "sent" }
    else
      render json: { error: response.message }, status: :unprocessable_entity
    end
  end
end
```

#### Rake Tasks

```bash
# Check configuration
rake poodle:config

# Test connection
rake poodle:test

# Send test email
rake poodle:send_test[recipient@example.com]

# Generate initializer
rake poodle:install
```

### Testing

The SDK includes comprehensive testing utilities for easy testing in your applications.

#### RSpec Integration

```ruby
# spec/spec_helper.rb or spec/rails_helper.rb
require 'poodle'

RSpec.configure do |config|
  config.include Poodle::TestHelpers

  config.before(:each) do
    Poodle.test_mode!
  end

  config.after(:each) do
    Poodle.clear_deliveries
  end
end
```

#### Testing Email Sending

```ruby
it "sends welcome email" do
  expect {
    UserMailer.send_welcome(user)
  }.to change { Poodle.deliveries.count }.by(1)

  email = Poodle.last_delivery
  expect(email[:to]).to eq(user.email)
  expect(email[:subject]).to include("Welcome")
  expect(email[:html]).to include(user.name)
end

it "sends notification emails" do
  service.send_notifications

  assert_email_sent(3)
  assert_email_sent_to("admin@example.com")
  assert_email_sent_with_subject("Alert")
end
```

### Error Handling

```ruby
begin
  response = client.send(email_data)
  puts "Email sent!" if response.success?
rescue Poodle::ValidationError => e
  puts "Validation failed: #{e.message}"
  e.errors.each do |field, messages|
    puts "#{field}: #{messages.join(', ')}"
  end
rescue Poodle::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Poodle::RateLimitError => e
  puts "Rate limited. Retry after: #{e.retry_after} seconds"
rescue Poodle::PaymentError => e
  puts "Payment required: #{e.message}"
  puts "Upgrade at: #{e.upgrade_url}"
rescue Poodle::ForbiddenError => e
  puts "Access forbidden: #{e.message}"
rescue Poodle::NetworkError => e
  puts "Network error: #{e.message}"
rescue Poodle::ServerError => e
  puts "Server error: #{e.message}"
rescue Poodle::Error => e
  puts "Poodle error: #{e.message}"
end
```

### Retry Logic

```ruby
def send_with_retry(client, email_data, max_retries: 3)
  retries = 0

  begin
    client.send(email_data)
  rescue Poodle::RateLimitError => e
    if retries < max_retries && e.retry_after
      retries += 1
      sleep(e.retry_after)
      retry
    else
      raise
    end
  rescue Poodle::NetworkError, Poodle::ServerError => e
    if retries < max_retries
      retries += 1
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      raise
    end
  end
end
```

## API Reference

### Client

#### `Poodle::Client.new(config_or_api_key, **options)`

Creates a new Poodle client.

**Parameters:**

- `config_or_api_key` - Configuration object, API key string, or nil
- `**options` - Additional options (base_url, timeout, debug, etc.)

#### `client.send(from:, to:, subject:, html: nil, text: nil)`

Sends an email with the specified parameters.

#### `client.send_email(email)`

Sends an Email object.

#### `client.send_html(from:, to:, subject:, html:)`

Sends an HTML-only email.

#### `client.send_text(from:, to:, subject:, text:)`

Sends a text-only email.

### Email

#### `Poodle::Email.new(from:, to:, subject:, html: nil, text: nil)`

Creates a new Email object with validation.

**Methods:**

- `#html?` - Returns true if HTML content is present
- `#text?` - Returns true if text content is present
- `#multipart?` - Returns true if both HTML and text are present
- `#content_size` - Returns total content size in bytes
- `#to_h` - Converts to hash for API requests

### EmailResponse

#### Properties

- `#success?` - Returns true if email was successfully queued
- `#failed?` - Returns true if email sending failed
- `#message` - Response message from API
- `#data` - Additional response data

### Configuration

#### `Poodle::Configuration.new(**options)`

Creates a new configuration object.

**Options:**

- `api_key` - Your Poodle API key
- `base_url` - API base URL
- `timeout` - Request timeout in seconds
- `connect_timeout` - Connection timeout in seconds
- `debug` - Enable debug logging
- `http_options` - Additional HTTP client options

## Error Types

| Error Class                   | Description              | HTTP Status |
| ----------------------------- | ------------------------ | ----------- |
| `Poodle::ValidationError`     | Invalid request data     | 400, 422    |
| `Poodle::AuthenticationError` | Invalid API key          | 401         |
| `Poodle::PaymentError`        | Payment required         | 402         |
| `Poodle::ForbiddenError`      | Access forbidden         | 403         |
| `Poodle::RateLimitError`      | Rate limit exceeded      | 429         |
| `Poodle::ServerError`         | Server error             | 5xx         |
| `Poodle::NetworkError`        | Network/connection error | Various     |

All errors inherit from `Poodle::Error` which provides:

- `#message` - Error message
- `#context` - Additional error context
- `#status_code` - HTTP status code (if applicable)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Contributions are welcome! Please read our [Contributing Guide](https://github.com/usepoodle/poodle-ruby/blob/main/CONTRIBUTING.md) for details on the process for submitting pull requests and our [Code of Conduct](https://github.com/usepoodle/poodle-ruby/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
