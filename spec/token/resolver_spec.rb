# frozen_string_literal: true

RSpec.describe Token::Resolver do
  it "has a version number" do
    expect(Token::Resolver::VERSION).not_to be_nil
  end

  it "has a Version module" do
    expect(Token::Resolver::Version::VERSION).to eq(Token::Resolver::VERSION)
  end

  describe ".parse" do
    it "returns a Document" do
      doc = described_class.parse("Hello {KJ|NAME}!")
      expect(doc).to be_a(Token::Resolver::Document)
    end

    it "accepts a custom config" do
      config = Token::Resolver::Config.new(pre: "<<", post: ">>", separators: [":"])
      doc = described_class.parse("Hello <<KJ:NAME>>!", config: config)
      expect(doc.token_keys).to eq(["KJ:NAME"])
    end
  end

  describe ".resolve" do
    it "resolves tokens in one step" do
      result = described_class.resolve(
        "Hello {KJ|NAME}, welcome to {KJ|PROJECT}!",
        {"KJ|NAME" => "World", "KJ|PROJECT" => "token-resolver"},
      )
      expect(result).to eq("Hello World, welcome to token-resolver!")
    end

    it "raises on unresolved tokens by default" do
      expect {
        described_class.resolve("{KJ|MISSING}", {})
      }.to raise_error(Token::Resolver::UnresolvedTokenError)
    end

    it "accepts on_missing option" do
      result = described_class.resolve("{KJ|MISSING}", {}, on_missing: :keep)
      expect(result).to eq("{KJ|MISSING}")
    end
  end
end
