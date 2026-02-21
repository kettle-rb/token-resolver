# frozen_string_literal: true

# External gems
require "version_gem"

# This gem - only version can be required (never autoloaded)
require_relative "resolver/version"

module Token
  # Token::Resolver provides configurable PEG-based (parslet) parsing and resolution
  # of structured tokens in arbitrary text.
  #
  # Tokens are configurable structured patterns like `{KJ|GEM_NAME}` that can be
  # detected in any file format and resolved against a replacement map.
  #
  # @example Parse a document to find tokens
  #   doc = Token::Resolver.parse("Hello {KJ|NAME}!")
  #   doc.token_keys  # => ["KJ|NAME"]
  #
  # @example Resolve tokens in one step
  #   result = Token::Resolver.resolve(
  #     "Hello {KJ|NAME}, welcome to {KJ|PROJECT}!",
  #     {"KJ|NAME" => "World", "KJ|PROJECT" => "token-resolver"}
  #   )
  #   # => "Hello World, welcome to token-resolver!"
  #
  module Resolver
    # Base error class for all token-resolver operations.
    # @api public
    class Error < StandardError; end

    # Raised when a token has no replacement value and on_missing is :raise.
    # @api public
    class UnresolvedTokenError < Error
      # @return [String] The token key that was not found
      attr_reader :token_key

      # @param token_key [String] The unresolved token key
      # @param message [String, nil] Optional custom message
      def initialize(token_key, message = nil)
        @token_key = token_key
        super(message || "Unresolved token: #{token_key}")
      end
    end

    # Autoload all classes
    autoload :Config, "token/resolver/config"
    autoload :Document, "token/resolver/document"
    autoload :Grammar, "token/resolver/grammar"
    autoload :Node, "token/resolver/node"
    autoload :Resolve, "token/resolver/resolve"
    autoload :Transform, "token/resolver/transform"

    class << self
      # Parse input text and return a Document.
      #
      # @param input [String] Text to parse for tokens
      # @param config [Config] Token configuration (default: Config.default)
      # @return [Document] Parsed document with text and token nodes
      #
      # @example
      #   doc = Token::Resolver.parse("Hello {KJ|NAME}!")
      #   doc.tokens.first.key  # => "KJ|NAME"
      def parse(input, config: Config.default)
        Document.new(input, config: config)
      end

      # Parse and resolve tokens in one step.
      #
      # @param input [String] Text containing tokens to resolve
      # @param replacements [Hash{String => String}] Map of token keys to replacement values
      # @param config [Config] Token configuration (default: Config.default)
      # @param on_missing [Symbol] Behavior for unresolved tokens (:raise, :keep, :remove)
      # @return [String] Resolved text with tokens replaced
      #
      # @example
      #   Token::Resolver.resolve("{KJ|NAME}", {"KJ|NAME" => "World"})
      #   # => "World"
      def resolve(input, replacements, config: Config.default, on_missing: :raise)
        doc = parse(input, config: config)
        resolver = Resolve.new(on_missing: on_missing)
        resolver.resolve(doc, replacements)
      end
    end
  end
end

Token::Resolver::Version.class_eval do
  extend VersionGem::Basic
end
