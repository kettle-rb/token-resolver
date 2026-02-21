# frozen_string_literal: true

RSpec.describe Token::Resolver::Document do
  let(:config) { Token::Resolver::Config.default }

  describe "#nodes" do
    it "returns an array of nodes" do
      doc = described_class.new("Hello {KJ|NAME}!", config: config)
      expect(doc.nodes).to be_an(Array)
      expect(doc.nodes.length).to eq(3)
    end
  end

  describe "#tokens" do
    it "returns only Token nodes" do
      doc = described_class.new("Hello {KJ|NAME} and {KJ|ORG}!", config: config)
      tokens = doc.tokens
      expect(tokens.length).to eq(2)
      expect(tokens).to all(be_a(Token::Resolver::Node::Token))
    end

    it "returns empty array when no tokens" do
      doc = described_class.new("Hello World!", config: config)
      expect(doc.tokens).to eq([])
    end
  end

  describe "#token_keys" do
    it "returns unique token keys" do
      doc = described_class.new("{KJ|NAME} and {KJ|NAME} and {KJ|ORG}", config: config)
      expect(doc.token_keys).to contain_exactly("KJ|NAME", "KJ|ORG")
    end

    it "returns empty array when no tokens" do
      doc = described_class.new("plain text", config: config)
      expect(doc.token_keys).to eq([])
    end
  end

  describe "#to_s" do
    it "roundtrips simple input" do
      input = "Hello World"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end

    it "roundtrips input with tokens" do
      input = "Hello {KJ|NAME}, welcome to {KJ|PROJECT}!"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end

    it "roundtrips input with adjacent tokens" do
      input = "{KJ|A}{KJ|B}"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end

    it "roundtrips multi-line input" do
      input = "line1 {KJ|A}\nline2 {KJ|B}\n"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end

    it "roundtrips input with emoji" do
      input = "🎨 {KJ|NAME} 🚀"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end

    it "roundtrips input with incomplete tokens" do
      input = "Hello {KJ|NAME world"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end
  end

  describe "#text_only?" do
    it "returns true when no tokens" do
      doc = described_class.new("Hello World!", config: config)
      expect(doc.text_only?).to be true
    end

    it "returns false when tokens present" do
      doc = described_class.new("Hello {KJ|NAME}!", config: config)
      expect(doc.text_only?).to be false
    end
  end

  describe "fast-path" do
    it "handles empty input" do
      doc = described_class.new("", config: config)
      expect(doc.nodes.length).to eq(1)
      expect(doc.nodes[0].content).to eq("")
      expect(doc.text_only?).to be true
    end

    it "handles nil-like empty input" do
      doc = described_class.new("", config: config)
      expect(doc.to_s).to eq("")
    end

    it "skips parslet when pre is not in input" do
      doc = described_class.new("no tokens here", config: config)
      expect(doc.nodes.length).to eq(1)
      expect(doc.nodes[0]).to be_a(Token::Resolver::Node::Text)
      expect(doc.text_only?).to be true
    end
  end

  describe "with custom config" do
    let(:config) { Token::Resolver::Config.new(pre: "<<", post: ">>", separators: [":"]) }

    it "parses tokens with custom delimiters" do
      doc = described_class.new("Hello <<KJ:NAME>> world", config: config)
      expect(doc.token_keys).to eq(["KJ:NAME"])
    end

    it "roundtrips with custom delimiters" do
      input = "Hello <<KJ:NAME>> world"
      doc = described_class.new(input, config: config)
      expect(doc.to_s).to eq(input)
    end
  end

  describe "with multi-segment tokens" do
    it "parses three-segment tokens" do
      doc = described_class.new("{KJ|SECTION|NAME}", config: config)
      token = doc.tokens.first
      expect(token.segments).to eq(["KJ", "SECTION", "NAME"])
      expect(token.key).to eq("KJ|SECTION|NAME")
    end

    context "with sequential separators" do
      let(:config) { Token::Resolver::Config.new(separators: ["|", ":"]) }

      it "parses tokens with mixed separators" do
        doc = described_class.new("{KJ|SECTION:NAME}", config: config)
        token = doc.tokens.first
        expect(token.segments).to eq(["KJ", "SECTION", "NAME"])
        expect(token.key).to eq("KJ|SECTION:NAME")
      end
    end
  end
end
