# frozen_string_literal: true

require_relative "lib/poodle/version"

Gem::Specification.new do |spec|
  spec.name = "poodle-ruby"
  spec.version = Poodle::VERSION
  spec.authors = ["Wilbert Liu"]
  spec.email = ["wilbert@usepoodle.com"]

  spec.summary = "Poodle Ruby SDK"
  spec.description = "Ruby SDK for the Poodle email sending API"
  spec.homepage = "https://usepoodle.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/usepoodle/poodle-ruby"
  spec.metadata["documentation_uri"] = "https://rubydoc.info/gems/poodle-ruby"
  spec.metadata["bug_tracker_uri"] = "https://github.com/usepoodle/poodle-ruby/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-net_http", "~> 3.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
