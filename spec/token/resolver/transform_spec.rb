# frozen_string_literal: true

RSpec.describe Token::Resolver::Transform do
  let(:config) { Token::Resolver::Config.default }

  describe ".apply" do
    it "returns empty array for nil" do
      expect(described_class.apply(nil, config)).to eq([])
    end

    it "returns empty array for empty tree" do
      expect(described_class.apply([], config)).to eq([])
    end

    it "coalesces adjacent text entries into a single Text node" do
      tree = [
        {text: Parslet::Slice.new(Parslet::Position.new("H", 0), "H")},
        {text: Parslet::Slice.new(Parslet::Position.new("i", 1), "i")},
      ]
      nodes = described_class.apply(tree, config)
      expect(nodes.length).to eq(1)
      expect(nodes[0]).to be_a(Token::Resolver::Node::Text)
      expect(nodes[0].content).to eq("Hi")
    end

    it "converts token entries to Token nodes" do
      # Simulate what parslet produces for a token
      tree = [
        {
          token: {
            seg: [
              Parslet::Slice.new(Parslet::Position.new("KJ", 0), "KJ"),
              Parslet::Slice.new(Parslet::Position.new("NAME", 0), "NAME"),
            ],
          },
        },
      ]
      nodes = described_class.apply(tree, config)
      expect(nodes.length).to eq(1)
      expect(nodes[0]).to be_a(Token::Resolver::Node::Token)
      expect(nodes[0].segments).to eq(["KJ", "NAME"])
    end

    it "handles mixed text and token entries" do
      tree = [
        {text: Parslet::Slice.new(Parslet::Position.new("A", 0), "A")},
        {
          token: {
            seg: [
              Parslet::Slice.new(Parslet::Position.new("X", 0), "X"),
              Parslet::Slice.new(Parslet::Position.new("Y", 0), "Y"),
            ],
          },
        },
        {text: Parslet::Slice.new(Parslet::Position.new("B", 0), "B")},
      ]
      nodes = described_class.apply(tree, config)
      expect(nodes.length).to eq(3)
      expect(nodes[0]).to be_a(Token::Resolver::Node::Text)
      expect(nodes[1]).to be_a(Token::Resolver::Node::Token)
      expect(nodes[2]).to be_a(Token::Resolver::Node::Text)
    end
  end
end
