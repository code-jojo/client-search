# frozen_string_literal: true

RSpec.describe ClientSearch do
  it "has a version number" do
    expect(ClientSearch::VERSION).not_to be_nil
    expect(ClientSearch::VERSION).to be_a(String)
    expect(ClientSearch::VERSION).to match(/\d+\.\d+\.\d+/)
  end
end
