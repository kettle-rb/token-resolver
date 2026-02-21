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
