# frozen_string_literal: true

RSpec.describe Token::Resolver::Node::Text do
  subject(:node) { described_class.new("Hello") }

  describe "#content" do
    it "returns the text content" do
      expect(node.content).to eq("Hello")
    end
  end

  describe "#to_s" do
    it "returns the text content" do
      expect(node.to_s).to eq("Hello")
    end
  end

  describe "#token?" do
    it "returns false" do
      expect(node.token?).to be false
    end
  end

  describe "#text?" do
    it "returns true" do
      expect(node.text?).to be true
    end
  end

  describe "frozen" do
    it "is frozen" do
      expect(node).to be_frozen
    end

    it "has frozen content" do
      expect(node.content).to be_frozen
    end
  end

  describe "#eql?" do
    it "considers nodes with same content equal" do
      a = described_class.new("Hello")
      b = described_class.new("Hello")
      expect(a).to eql(b)
    end

    it "considers nodes with different content not equal" do
      a = described_class.new("Hello")
      b = described_class.new("World")
      expect(a).not_to eql(b)
    end

    it "is not equal to non-Text objects" do
      expect(node).not_to eql("Hello")
    end
  end

  describe "#hash" do
    it "is equal for equal nodes" do
      a = described_class.new("Hello")
      b = described_class.new("Hello")
      expect(a.hash).to eq(b.hash)
    end
  end

  describe "#inspect" do
    it "includes the class name and content" do
      expect(node.inspect).to include("Text")
      expect(node.inspect).to include("Hello")
    end
  end
end

RSpec.describe Token::Resolver::Node::Token do
  let(:config) { Token::Resolver::Config.default }
  subject(:node) { described_class.new(["KJ", "GEM_NAME"], config) }

  describe "#segments" do
    it "returns the segments" do
      expect(node.segments).to eq(["KJ", "GEM_NAME"])
    end
  end

  describe "#config" do
    it "returns the config" do
      expect(node.config).to eq(config)
    end
  end

  describe "#key" do
    context "with single separator" do
      it "joins segments with the separator" do
        expect(node.key).to eq("KJ|GEM_NAME")
      end
    end

    context "with sequential separators" do
      let(:config) { Token::Resolver::Config.new(separators: ["|", ":"]) }
      let(:node) { described_class.new(["KJ", "SECTION", "NAME"], config) }

      it "uses separators in order" do
        expect(node.key).to eq("KJ|SECTION:NAME")
      end
    end

    context "with sequential separators and more segments than separators" do
      let(:config) { Token::Resolver::Config.new(separators: ["|", ":"]) }
      let(:node) { described_class.new(["KJ", "A", "B", "C"], config) }

      it "repeats the last separator" do
        expect(node.key).to eq("KJ|A:B:C")
      end
    end

    context "with single segment" do
      let(:config) { Token::Resolver::Config.new(min_segments: 1) }
      let(:node) { described_class.new(["SOLO"], config) }

      it "returns just the segment" do
        expect(node.key).to eq("SOLO")
      end
    end
  end

  describe "#prefix" do
    it "returns the first segment" do
      expect(node.prefix).to eq("KJ")
    end
  end

  describe "#to_s" do
    it "reconstructs the original token string" do
      expect(node.to_s).to eq("{KJ|GEM_NAME}")
    end

    context "with custom config" do
      let(:config) { Token::Resolver::Config.new(pre: "<<", post: ">>", separators: [":"]) }
      let(:node) { described_class.new(["KJ", "NAME"], config) }

      it "uses the config's delimiters" do
        expect(node.to_s).to eq("<<KJ:NAME>>")
      end
    end

    context "with sequential separators" do
      let(:config) { Token::Resolver::Config.new(separators: ["|", ":"]) }
      let(:node) { described_class.new(["KJ", "SECTION", "NAME"], config) }

      it "uses correct separators" do
        expect(node.to_s).to eq("{KJ|SECTION:NAME}")
      end
    end
  end

  describe "#token?" do
    it "returns true" do
      expect(node.token?).to be true
    end
  end

  describe "#text?" do
    it "returns false" do
      expect(node.text?).to be false
    end
  end

  describe "frozen" do
    it "is frozen" do
      expect(node).to be_frozen
    end

    it "has frozen segments" do
      expect(node.segments).to be_frozen
      node.segments.each { |s| expect(s).to be_frozen }
    end
  end

  describe "#eql?" do
    it "considers tokens with same segments and config equal" do
      a = described_class.new(["KJ", "NAME"], config)
      b = described_class.new(["KJ", "NAME"], config)
      expect(a).to eql(b)
    end

    it "considers tokens with different segments not equal" do
      a = described_class.new(["KJ", "A"], config)
      b = described_class.new(["KJ", "B"], config)
      expect(a).not_to eql(b)
    end
  end

  describe "#hash" do
    it "is equal for equal tokens" do
      a = described_class.new(["KJ", "NAME"], config)
      b = described_class.new(["KJ", "NAME"], config)
      expect(a.hash).to eq(b.hash)
    end
  end

  describe "#inspect" do
    it "includes the class name and token string" do
      expect(node.inspect).to include("Token")
      expect(node.inspect).to include("{KJ|GEM_NAME}")
    end
  end
end
