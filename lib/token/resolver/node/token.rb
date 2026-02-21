# frozen_string_literal: true

module Token
  module Resolver
    module Node
      # Represents a structured token found in the input.
      #
      # A token consists of segments separated by configured separators,
      # wrapped in pre/post delimiters. For example, with default config,
      # `{KJ|GEM_NAME}` has segments `["KJ", "GEM_NAME"]`.
      #
      # Token nodes are frozen after creation.
      #
      # @example Single separator
      #   token = Token::Resolver::Node::Token.new(["KJ", "GEM_NAME"], config)
      #   token.key       # => "KJ|GEM_NAME"
      #   token.prefix    # => "KJ"
      #   token.segments  # => ["KJ", "GEM_NAME"]
      #   token.to_s      # => "{KJ|GEM_NAME}"
      #
      # @example Sequential separators
      #   config = Config.new(separators: ["|", ":"])
      #   token = Token::Resolver::Node::Token.new(["KJ", "SECTION", "NAME"], config)
      #   token.key       # => "KJ|SECTION:NAME"
      #   token.to_s      # => "{KJ|SECTION:NAME}"
      #
      class Token
        # @return [Array<String>] The token segments
        attr_reader :segments

        # @return [Config] The config used to parse this token
        attr_reader :config

        # @param segments [Array<String>] The token segments
        # @param config [Config] The config that defined this token's structure
        def initialize(segments, config)
          @segments = segments.map { |s| s.frozen? ? s : s.dup.freeze }.freeze
          @config = config
          freeze
        end

        # The canonical key for this token, suitable for use as a replacement map key.
        #
        # Joins segments using the actual separators in order. For `separators: ["|", ":"]`
        # and segments `["KJ", "SECTION", "NAME"]`, returns `"KJ|SECTION:NAME"`.
        #
        # @return [String]
        def key
          return @segments[0] if @segments.length == 1

          result = +""
          @segments.each_with_index do |seg, i|
            if i > 0
              result << @config.separator_at(i - 1)
            end
            result << seg
          end
          result.freeze
        end

        # The first segment (typically a prefix/namespace like "KJ").
        #
        # @return [String]
        def prefix
          @segments[0]
        end

        # Reconstruct the original token string with delimiters.
        #
        # @return [String]
        def to_s
          "#{@config.pre}#{key}#{@config.post}"
        end

        # @return [Boolean]
        def token?
          true
        end

        # @return [Boolean]
        def text?
          false
        end

        # Equality based on segments and config.
        #
        # @param other [Object]
        # @return [Boolean]
        def eql?(other)
          other.is_a?(Token) && segments == other.segments && config == other.config
        end

        alias_method :==, :eql?

        # @return [Integer]
        def hash
          [self.class, segments, config].hash
        end

        # @return [String]
        def inspect
          "#<#{self.class} #{to_s.inspect} segments=#{segments.inspect}>"
        end
      end
    end
  end
end
