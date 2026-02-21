# frozen_string_literal: true

RSpec.describe Token::Resolver::Config do
  describe ".default" do
    subject(:config) { described_class.default }

    it "has default pre" do
      expect(config.pre).to eq("{")
    end

    it "has default post" do
      expect(config.post).to eq("}")
    end

    it "has default separators" do
      expect(config.separators).to eq(["|"])
    end

    it "has default min_segments" do
      expect(config.min_segments).to eq(2)
    end

    it "has default max_segments" do
      expect(config.max_segments).to be_nil
    end

    it "is frozen" do
      expect(config).to be_frozen
    end

    it "returns the same object on repeated calls" do
      expect(described_class.default).to equal(described_class.default)
    end
  end

  describe "#initialize" do
    it "accepts custom delimiters" do
      config = described_class.new(pre: "<<", post: ">>", separators: [":"])
      expect(config.pre).to eq("<<")
      expect(config.post).to eq(">>")
      expect(config.separators).to eq([":"])
    end

    it "accepts custom segment constraints" do
      config = described_class.new(min_segments: 3, max_segments: 5)
      expect(config.min_segments).to eq(3)
      expect(config.max_segments).to eq(5)
    end

    it "freezes the config" do
      config = described_class.new
      expect(config).to be_frozen
    end

    it "freezes the separators array" do
      config = described_class.new
      expect(config.separators).to be_frozen
    end

    it "freezes individual strings" do
      config = described_class.new
      expect(config.pre).to be_frozen
      expect(config.post).to be_frozen
      config.separators.each { |s| expect(s).to be_frozen }
    end
  end

  describe "validation" do
    it "raises on empty pre" do
      expect { described_class.new(pre: "") }.to raise_error(ArgumentError, /pre must be/)
    end

    it "raises on nil pre" do
      expect { described_class.new(pre: nil) }.to raise_error(ArgumentError, /pre must be/)
    end

    it "raises on empty post" do
      expect { described_class.new(post: "") }.to raise_error(ArgumentError, /post must be/)
    end

    it "raises on empty separators array" do
      expect { described_class.new(separators: []) }.to raise_error(ArgumentError, /separators must be/)
    end

    it "raises on empty separator string" do
      expect { described_class.new(separators: [""]) }.to raise_error(ArgumentError, /separators\[0\] must be/)
    end

    it "raises on min_segments < 1" do
      expect { described_class.new(min_segments: 0) }.to raise_error(ArgumentError, /min_segments must be/)
    end

    it "raises on non-integer min_segments" do
      expect { described_class.new(min_segments: 1.5) }.to raise_error(ArgumentError, /min_segments must be/)
    end

    it "raises on max_segments < min_segments" do
      expect { described_class.new(min_segments: 3, max_segments: 2) }.to raise_error(ArgumentError, /max_segments.*must be >= min_segments/)
    end

    it "raises on non-integer max_segments" do
      expect { described_class.new(max_segments: 1.5) }.to raise_error(ArgumentError, /max_segments must be/)
    end
  end

  describe "#separator_at" do
    context "with single separator" do
      let(:config) { described_class.new(separators: ["|"]) }

      it "returns the separator for index 0" do
        expect(config.separator_at(0)).to eq("|")
      end

      it "repeats the last separator for higher indices" do
        expect(config.separator_at(5)).to eq("|")
      end
    end

    context "with multiple separators" do
      let(:config) { described_class.new(separators: ["|", ":"]) }

      it "returns first separator for index 0" do
        expect(config.separator_at(0)).to eq("|")
      end

      it "returns second separator for index 1" do
        expect(config.separator_at(1)).to eq(":")
      end

      it "repeats last separator for higher indices" do
        expect(config.separator_at(2)).to eq(":")
        expect(config.separator_at(10)).to eq(":")
      end
    end
  end

  describe "#eql? and #hash" do
    it "considers identical configs equal" do
      a = described_class.new
      b = described_class.new
      expect(a).to eql(b)
      expect(a.hash).to eq(b.hash)
    end

    it "considers different configs not equal" do
      a = described_class.new(pre: "{")
      b = described_class.new(pre: "<<")
      expect(a).not_to eql(b)
    end

    it "works as a Hash key" do
      a = described_class.new
      b = described_class.new
      hash = {a => "value"}
      expect(hash[b]).to eq("value")
    end

    it "aliases == to eql?" do
      a = described_class.new
      b = described_class.new
      expect(a == b).to be true
    end
  end
end
