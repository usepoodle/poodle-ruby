# Contributing to Poodle Ruby SDK

Thank you for your interest in contributing to the Poodle Ruby SDK! We welcome contributions from the community.

## Development Setup

### Requirements

- Ruby 3.0 or higher
- Bundler
- Git

### Setup

1. Fork the repository
2. Clone your fork:

   ```bash
   git clone https://github.com/yourusername/poodle-ruby.git
   cd poodle-ruby
   ```

3. Install dependencies:
   ```bash
   bundle install
   ```

## Development Workflow

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/poodle/client_spec.rb

# Run tests with coverage
bundle exec rspec
# Coverage report will be generated in coverage/index.html
```

### Code Quality

```bash
# Check code style
bundle exec rubocop

# Fix code style issues automatically
bundle exec rubocop -a

# Generate documentation
bundle exec yard doc

# View documentation
bundle exec yard server
```

### Making Changes

1. Create a feature branch:

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes
3. Write or update tests
4. Ensure all tests pass and code style is correct
5. Commit your changes with a descriptive message
6. Push to your fork
7. Create a pull request

## Code Standards

### Ruby Standards

- Follow the Ruby Style Guide
- Use RuboCop for code style enforcement (configuration in `.rubocop.yml`)
- Maintain Ruby 3.0+ compatibility
- Use frozen string literals (`# frozen_string_literal: true`)
- Write comprehensive YARD documentation

### Testing Standards

- Write RSpec tests for all new functionality
- Maintain or improve test coverage
- Use descriptive test descriptions
- Test both success and failure scenarios
- Use VCR for HTTP interaction testing when appropriate

### Documentation Standards

- Document all public methods with YARD
- Update README.md if adding new features
- Include code examples in documentation
- Keep examples in the `examples/` directory up to date

## Pull Request Process

1. Ensure your code follows the existing style and conventions
2. Run the full test suite and ensure all tests pass
3. Run RuboCop and fix any style issues
4. Update documentation as needed
5. Write a clear PR description explaining your changes
6. Link any relevant issues

## We Use [Github Flow](https://docs.github.com/en/get-started/using-github/github-flow)

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code follows RuboCop guidelines.
6. Issue that pull request!

## Any contributions you make will be under the MIT Software License

In short, when you submit code changes, your submissions are understood to be under the same [MIT License](http://choosealicense.com/licenses/mit/) that covers the project. Feel free to contact the maintainers if that's a concern.

## Report bugs using GitHub's [issue tracker](https://github.com/usepoodle/poodle-ruby/issues)

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/usepoodle/poodle-ruby/issues/new); it's that easy!

## Write bug reports with detail, background, and sample code

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can.
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Use a Consistent Coding Style

- Follow the RuboCop configuration in `.rubocop.yml`
- Use double quotes for strings
- 2 spaces for indentation
- Maximum line length of 120 characters
- Write meaningful commit messages
- Use descriptive variable and method names

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
