# frozen_string_literal: true

RSpec.describe ClientSearchCli::CLI do
  it "has a version command" do
    expect { described_class.new.version }.to output(/client-search-cli version/).to_stdout
  end

  # More tests to be added as we implement functionality
end 