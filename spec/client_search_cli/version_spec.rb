# frozen_string_literal: true

RSpec.describe ClientSearchCli::VERSION do
  it "has a version number" do
    expect(ClientSearchCli::VERSION).not_to be_nil
    expect(ClientSearchCli::VERSION).to be_a(String)
    expect(ClientSearchCli::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end 