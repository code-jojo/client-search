require_relative "lib/client_search_cli/version"

Gem::Specification.new do |spec|
  spec.name = "client-search-cli"
  spec.version = ClientSearchCli::VERSION
  spec.authors = ["ShiftCare Developer"]
  spec.email = ["dev@example.com"]

  spec.summary = "Command-line tool for searching ShiftCare clients"
  spec.description = "A CLI application that allows users to search for clients using the ShiftCare API"
  spec.homepage = "https://github.com/shiftcare/client-search-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shiftcare/client-search-cli"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "httparty", "~> 0.21.0"
  spec.add_dependency "csv", "~> 3.3"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end 