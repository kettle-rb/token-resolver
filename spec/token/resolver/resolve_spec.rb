# frozen_string_literal: true

RSpec.describe Token::Resolver::Resolve do
  let(:config) { Token::Resolver::Config.default }

  describe "#initialize" do
    it "defaults to on_missing: :raise" do
      resolver = described_class.new
      expect(resolver.on_missing).to eq(:raise)
    end

    it "accepts :keep" do
      resolver = described_class.new(on_missing: :keep)
      expect(resolver.on_missing).to eq(:keep)
    end

    it "accepts :remove" do
      resolver = described_class.new(on_missing: :remove)
      expect(resolver.on_missing).to eq(:remove)
    end

    it "raises on invalid on_missing" do
      expect { described_class.new(on_missing: :invalid) }.to raise_error(ArgumentError, /Invalid on_missing/)
    end
  end

  describe "#resolve" do
    subject(:resolver) { described_class.new(on_missing: on_missing) }

    let(:on_missing) { :raise }

    context "with full replacement" do
      it "replaces all tokens" do
        doc = Token::Resolver::Document.new("Hello {KJ|NAME}!", config: config)
        result = resolver.resolve(doc, {"KJ|NAME" => "World"})
        expect(result).to eq("Hello World!")
      end

      it "replaces multiple different tokens" do
        doc = Token::Resolver::Document.new("{KJ|A} and {KJ|B}", config: config)
        result = resolver.resolve(doc, {"KJ|A" => "X", "KJ|B" => "Y"})
        expect(result).to eq("X and Y")
      end

      it "replaces duplicate tokens" do
        doc = Token::Resolver::Document.new("{KJ|A} and {KJ|A}", config: config)
        result = resolver.resolve(doc, {"KJ|A" => "X"})
        expect(result).to eq("X and X")
      end
    end

    context "with no tokens" do
      it "returns the input unchanged" do
        doc = Token::Resolver::Document.new("Hello World!", config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq("Hello World!")
      end
    end

    context "with empty input" do
      it "returns empty string" do
        doc = Token::Resolver::Document.new("", config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq("")
      end
    end

    context "when on_missing is :raise" do
      let(:on_missing) { :raise }

      it "raises UnresolvedTokenError for missing tokens" do
        doc = Token::Resolver::Document.new("{KJ|MISSING}", config: config)
        expect { resolver.resolve(doc, {}) }.to raise_error(
          Token::Resolver::UnresolvedTokenError,
          /KJ\|MISSING/,
        )
      end

      it "includes the token key in the error" do
        doc = Token::Resolver::Document.new("{KJ|FOO}", config: config)
        begin
          resolver.resolve(doc, {})
        rescue Token::Resolver::UnresolvedTokenError => e
          expect(e.token_key).to eq("KJ|FOO")
        end
      end
    end

    context "when on_missing is :keep" do
      let(:on_missing) { :keep }

      it "keeps the original token string" do
        doc = Token::Resolver::Document.new("Hello {KJ|MISSING}!", config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq("Hello {KJ|MISSING}!")
      end

      it "resolves known tokens and keeps unknown ones" do
        doc = Token::Resolver::Document.new("{KJ|KNOWN} and {KJ|UNKNOWN}", config: config)
        result = resolver.resolve(doc, {"KJ|KNOWN" => "yes"})
        expect(result).to eq("yes and {KJ|UNKNOWN}")
      end
    end

    context "when on_missing is :remove" do
      let(:on_missing) { :remove }

      it "removes unresolved tokens" do
        doc = Token::Resolver::Document.new("Hello {KJ|MISSING}!", config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq("Hello !")
      end
    end

    context "with replacement values containing token-like strings" do
      it "does NOT re-parse replacement values" do
        doc = Token::Resolver::Document.new("{KJ|A}", config: config)
        result = resolver.resolve(doc, {"KJ|A" => "{KJ|B}"})
        expect(result).to eq("{KJ|B}")
      end
    end

    context "with a node array directly" do
      it "works with an array of nodes" do
        nodes = [
          Token::Resolver::Node::Text.new("Hi "),
          Token::Resolver::Node::Token.new(["KJ", "NAME"], config),
        ]
        result = resolver.resolve(nodes, {"KJ|NAME" => "World"})
        expect(result).to eq("Hi World")
      end
    end

    context "with invalid input" do
      it "raises ArgumentError for non-Document/Array" do
        expect { resolver.resolve("string", {}) }.to raise_error(ArgumentError, /Expected Document or Array/)
      end
    end

    context "with invalid replacement keys" do
      it "raises ArgumentError for keys with spaces" do
        doc = Token::Resolver::Document.new("hello", config: config)
        expect {
          resolver.resolve(doc, {" |repo_name" => "x"})
        }.to raise_error(ArgumentError, /Invalid replacement key/)
      end

      it "raises ArgumentError for keys with punctuation in segments" do
        doc = Token::Resolver::Document.new("hello", config: config)
        expect {
          resolver.resolve(doc, {"KJ|File.exist?(fp)" => "x"})
        }.to raise_error(ArgumentError, /Invalid replacement key/)
      end

      it "accepts valid word-character keys" do
        doc = Token::Resolver::Document.new("{KJ|NAME}", config: config)
        expect {
          resolver.resolve(doc, {"KJ|NAME" => "x"})
        }.not_to raise_error
      end

      it "accepts valid multi-separator keys" do
        multi_config = Token::Resolver::Config.new(separators: ["|", ":"])
        doc = Token::Resolver::Document.new("{KJ|AUTHOR:NAME}", config: multi_config)
        expect {
          resolver.resolve(doc, {"KJ|AUTHOR:NAME" => "x"})
        }.not_to raise_error
      end

      it "skips validation when given an Array instead of Document" do
        nodes = [Token::Resolver::Node::Text.new("hi")]
        expect {
          resolver.resolve(nodes, {" bad|key" => "x"})
        }.not_to raise_error
      end
    end

    context "with Ruby and shell syntax that resembles tokens" do
      let(:on_missing) { :keep }

      it "preserves Ruby block parameters unchanged" do
        input = "items.map { |x| x.to_s }"
        doc = Token::Resolver::Document.new(input, config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq(input)
      end

      it "preserves multi-line Ruby with block params and real tokens" do
        input = <<~RUBY
          git_source(:codeberg) { |repo_name| "https://codeberg.org/\#{repo_name}" }
          gem "{KJ|GEM_NAME}", "~> 1.0"
        RUBY
        doc = Token::Resolver::Document.new(input, config: config)
        result = resolver.resolve(doc, {"KJ|GEM_NAME" => "my-gem"})
        expected = <<~RUBY
          git_source(:codeberg) { |repo_name| "https://codeberg.org/\#{repo_name}" }
          gem "my-gem", "~> 1.0"
        RUBY
        expect(result).to eq(expected)
      end

      it "preserves shell variable expansion with pipes" do
        input = 'export CLASSPATH="${JARS_DIR}/jtreesitter.jar${CLASSPATH:+:$CLASSPATH}"'
        doc = Token::Resolver::Document.new(input, config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq(input)
      end

      it "preserves gemspec cert_chain block with pipes" do
        input = "cert_chain.select! { |fp| File.exist?(fp) }"
        doc = Token::Resolver::Document.new(input, config: config)
        result = resolver.resolve(doc, {})
        expect(result).to eq(input)
      end
    end
  end
end
