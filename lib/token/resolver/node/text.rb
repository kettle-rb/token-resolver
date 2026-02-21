# frozen_string_literal: true

module Token
  module Resolver
    module Node
      # Represents plain text content (not a token).
      #
      # Text nodes hold the literal string content between (or outside of) tokens.
      # They are frozen after creation.
      #
      # @example
      #   text = Token::Resolver::Node::Text.new("Hello ")
      #   text.to_s     # => "Hello "
      #   text.content  # => "Hello "
      #
      class Text
        # @return [String] The text content
        attr_reader :content

        # @param content [String] The text content
        def initialize(content)
          @content = content.frozen? ? content : content.dup.freeze
          freeze
        end

        # @return [String] The text content
        def to_s
          @content
        end

        # @return [Boolean]
        def token?
          false
        end

        # @return [Boolean]
        def text?
          true
        end

        # Equality based on content.
        #
        # @param other [Object]
        # @return [Boolean]
        def eql?(other)
          other.is_a?(Text) && content == other.content
        end

        alias_method :==, :eql?

        # @return [Integer]
        def hash
          [self.class, content].hash
        end

        # @return [String]
        def inspect
          "#<#{self.class} #{content.inspect}>"
        end
      end
    end
  end
end
