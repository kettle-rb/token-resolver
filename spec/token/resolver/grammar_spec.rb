# frozen_string_literal: true

RSpec.describe Token::Resolver::Grammar do
  after { described_class.clear_cache! }

  let(:default_config) { Token::Resolver::Config.default }

  describe ".build" do
    it "returns a Parslet::Parser subclass" do
      parser_class = described_class.build(default_config)
      expect(parser_class).to be < Parslet::Parser
    end

    it "caches parser classes for identical configs" do
      a = described_class.build(default_config)
      b = described_class.build(Token::Resolver::Config.new)
      expect(a).to equal(b)
    end

    it "builds different classes for different configs" do
      alt_config = Token::Resolver::Config.new(pre: "<<", post: ">>")
      a = described_class.build(default_config)
      b = described_class.build(alt_config)
      expect(a).not_to equal(b)
    end
  end

  describe "parsing" do
    subject(:parser) { described_class.build(config).new }

    let(:config) { default_config }

    context "with empty input" do
      it "returns empty result" do
        result = parser.parse("")
        # Parslet returns empty string or empty array for empty repeat
        expect(result).to satisfy { |r| r == "" || (r.respond_to?(:empty?) && r.empty?) }
      end
    end

    context "with no tokens" do
      it "parses plain text into text entries" do
        result = parser.parse("Hello World")
        texts = result.select { |e| e.key?(:text) }
        expect(texts).not_to be_empty
        expect(texts.map { |t| t[:text].to_s }.join).to eq("Hello World")
      end
    end

    context "with a single token" do
      it "parses the token" do
        result = parser.parse("{KJ|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with token surrounded by text" do
      it "parses text-token-text" do
        result = parser.parse("Hello {KJ|NAME} there")
        tokens = result.select { |e| e.key?(:token) }
        texts = result.select { |e| e.key?(:text) }
        expect(tokens.length).to eq(1)
        expect(texts).not_to be_empty
      end
    end

    context "with adjacent tokens" do
      it "parses both tokens" do
        result = parser.parse("{KJ|A}{KJ|B}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(2)
      end
    end

    context "with token at start" do
      it "parses the token" do
        result = parser.parse("{KJ|NAME} end")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with token at end" do
      it "parses the token" do
        result = parser.parse("start {KJ|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with incomplete token (no closing delimiter)" do
      it "treats it as text" do
        result = parser.parse("Hello {KJ|NAME world")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(0)
      end
    end

    context "with pre delimiter not followed by valid structure" do
      it "treats it as text" do
        result = parser.parse("Hello { world")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(0)
      end
    end

    context "with multi-line content" do
      it "finds tokens across lines" do
        input = "line1 {KJ|A}\nline2 {KJ|B}\n"
        result = parser.parse(input)
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(2)
      end
    end

    context "with Unicode content" do
      it "handles emoji in surrounding text" do
        result = parser.parse("🎨 {KJ|NAME} 🚀")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with three segments" do
      it "parses a multi-segment token" do
        result = parser.parse("{KJ|SECTION|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with alternative config" do
      let(:config) { Token::Resolver::Config.new(pre: "<<", post: ">>", separators: [":"]) }

      it "parses tokens with custom delimiters" do
        result = parser.parse("Hello <<KJ:NAME>> world")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with min_segments enforcement" do
      let(:config) { Token::Resolver::Config.new(min_segments: 3) }

      it "rejects tokens with too few segments" do
        result = parser.parse("{KJ|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(0)
      end

      it "accepts tokens with enough segments" do
        result = parser.parse("{KJ|SECTION|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end
    end

    context "with max_segments enforcement" do
      let(:config) { Token::Resolver::Config.new(min_segments: 2, max_segments: 2) }

      it "accepts tokens with exact segment count" do
        result = parser.parse("{KJ|NAME}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(1)
      end

      it "rejects tokens with too many segments" do
        result = parser.parse("{KJ|A|B|C}")
        tokens = result.select { |e| e.key?(:token) }
        expect(tokens.length).to eq(0)
      end
    end
  end

  describe ".clear_cache!" do
    it "empties the cache" do
      described_class.build(default_config)
      described_class.clear_cache!
      # After clearing, building again should create a new class
      a = described_class.build(default_config)
      described_class.clear_cache!
      b = described_class.build(default_config)
      expect(a).not_to equal(b)
    end
  end
end
