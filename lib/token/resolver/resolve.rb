# frozen_string_literal: true

module Token
  module Resolver
    # Resolves tokens in a parsed Document using a replacement map.
    #
    # Text nodes pass through unchanged. Token nodes are looked up in the
    # replacement map by their key. Missing tokens are handled according
    # to the `on_missing` policy.
    #
    # @example Resolve all tokens
    #   doc = Document.new("Hello {KJ|NAME}!")
    #   resolver = Resolve.new
    #   resolver.resolve(doc, {"KJ|NAME" => "World"})
    #   # => "Hello World!"
    #
    # @example Keep unresolved tokens
    #   resolver = Resolve.new(on_missing: :keep)
    #   resolver.resolve(doc, {})
    #   # => "Hello {KJ|NAME}!"
    #
    # @example Remove unresolved tokens
    #   resolver = Resolve.new(on_missing: :remove)
    #   resolver.resolve(doc, {})
    #   # => "Hello !"
    #
    class Resolve
      VALID_ON_MISSING = %i[raise keep remove].freeze

      # @return [Symbol] Policy for unresolved tokens (:raise, :keep, :remove)
      attr_reader :on_missing

      # @param on_missing [Symbol] Behavior for unresolved tokens
      # @raise [ArgumentError] If on_missing is invalid
      def initialize(on_missing: :raise)
        unless VALID_ON_MISSING.include?(on_missing)
          raise ArgumentError,
            "Invalid on_missing: #{on_missing.inspect}. Must be one of: #{VALID_ON_MISSING.map(&:inspect).join(", ")}"
        end

        @on_missing = on_missing
      end

      # Resolve tokens in a document or node array using a replacement map.
      #
      # Resolution is single-pass — replacement values are NOT re-scanned for tokens.
      #
      # @param document_or_nodes [Document, Array<Node::Text, Node::Token>] Parsed input
      # @param replacements [Hash{String => String}] Map of token keys to replacement values
      # @return [String] Resolved text
      #
      # @raise [UnresolvedTokenError] If on_missing is :raise and a token has no replacement
      # @raise [ArgumentError] If a replacement key contains characters outside the config's segment_pattern
      def resolve(document_or_nodes, replacements)
        nodes, config = case document_or_nodes
        when Document
          [document_or_nodes.nodes, document_or_nodes.config]
        when Array
          [document_or_nodes, nil]
        else
          raise ArgumentError, "Expected Document or Array of nodes, got #{document_or_nodes.class}"
        end

        validate_replacement_keys!(replacements, config) if config && !replacements.empty?

        result = +""
        nodes.each do |node|
          if node.token?
            replacement = replacements[node.key]
            if replacement
              result << replacement
            else
              handle_missing(node, result)
            end
          else
            result << node.to_s
          end
        end
        result
      end

      private

      def handle_missing(token_node, result)
        case @on_missing
        when :raise
          raise UnresolvedTokenError.new(token_node.key)
        when :keep
          result << token_node.to_s
        when :remove
          # emit nothing
        end
      end

      # Validate that all replacement keys only contain characters allowed by the config.
      # Each key is composed of segments (matching segment_pattern) joined by separators.
      #
      # @param replacements [Hash{String => String}]
      # @param config [Config]
      # @raise [ArgumentError] If any key contains invalid characters
      def validate_replacement_keys!(replacements, config)
        # Build a regex that matches a valid key: segment (sep segment)*
        seg = config.segment_pattern
        seps = config.separators.map { |s| Regexp.escape(s) }.join("|")
        valid_key_re = /\A#{seg}+((?:#{seps})#{seg}+)*\z/

        replacements.each_key do |key|
          unless valid_key_re.match?(key)
            raise ArgumentError,
              "Invalid replacement key: #{key.inspect}. " \
                "Key segments must match #{config.segment_pattern.inspect} " \
                "and be separated by one of #{config.separators.inspect}."
          end
        end
      end
    end
  end
end
