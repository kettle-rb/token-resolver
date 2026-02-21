# frozen_string_literal: true

module Token
  module Resolver
    # Parses input text and provides access to the resulting text and token nodes.
    #
    # Document is the primary public API for parsing. It uses Grammar to parse
    # the input and Transform to convert the parse tree into node objects.
    #
    # @example Basic usage
    #   doc = Token::Resolver::Document.new("Hello {KJ|NAME}!")
    #   doc.nodes       # => [Text("Hello "), Token(["KJ", "NAME"]), Text("!")]
    #   doc.tokens      # => [Token(["KJ", "NAME"])]
    #   doc.token_keys  # => ["KJ|NAME"]
    #   doc.to_s        # => "Hello {KJ|NAME}!"
    #   doc.text_only?  # => false
    #
    # @example Fast-path for text without tokens
    #   doc = Token::Resolver::Document.new("No tokens here")
    #   doc.text_only?  # => true
    #
    class Document
      # @return [Array<Node::Text, Node::Token>] Parsed nodes
      attr_reader :nodes

      # @return [Config] The config used for parsing
      attr_reader :config

      # Parse input text into a Document.
      #
      # @param input [String] Text to parse for tokens
      # @param config [Config] Token configuration (default: Config.default)
      def initialize(input, config: Config.default)
        @config = config
        @input = input
        @nodes = parse(input)
      end

      # Return only the Token nodes.
      #
      # @return [Array<Node::Token>]
      def tokens
        @tokens ||= @nodes.select(&:token?)
      end

      # Return the unique token keys found in the input.
      #
      # @return [Array<String>]
      def token_keys
        @token_keys ||= tokens.map(&:key).uniq
      end

      # Reconstruct the original input from nodes (roundtrip fidelity).
      #
      # @return [String]
      def to_s
        @nodes.map(&:to_s).join
      end

      # Whether the input contains no tokens.
      #
      # @return [Boolean]
      def text_only?
        tokens.empty?
      end

      private

      def parse(input)
        # Fast-path: if input doesn't contain the pre delimiter, no tokens possible
        return [Node::Text.new(input)] if input.nil? || input.empty? || !input.include?(@config.pre)

        parser_class = Grammar.build(@config)
        tree = parser_class.new.parse(input)
        Transform.apply(tree, @config)
      rescue Parslet::ParseFailed
        # Grammar should never fail, but if it does, treat entire input as text
        [Node::Text.new(input)]
      end
    end
  end
end
