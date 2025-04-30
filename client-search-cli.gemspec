# frozen_string_literal: true

require_relative "lib/client_search_cli/version"

Gem::Specification.new do |spec|
  spec.name = "client-search-cli"
  spec.version = ClientSearchCli::VERSION
  spec.authors = ["Junrill Galvez"]
  spec.email = ["code.junrill@gmail.com"]

  spec.summary = "Command-line tool for searching ShiftCare clients"
  spec.description = "A CLI application that allows users to search for clients using the ShiftCare API"
  spec.homepage = "https://github.com/code-jojo/client-search-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/code-jojo/client-search-cli"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.glob("{bin,lib}/**/*") + %w[LICENSE.txt README.md]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "csv", "~> 3.3"
  spec.add_dependency "httparty", "~> 0.21.0"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "thor", "~> 1.2"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
