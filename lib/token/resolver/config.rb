# frozen_string_literal: true

module Token
  module Resolver
    # Configuration object defining the token structure for parsing.
    #
    # A Config describes what tokens look like: their opening/closing delimiters,
    # segment separators, and segment count constraints. Configs are frozen after
    # initialization and implement #hash/#eql? for grammar caching.
    #
    # @example Default config (tokens like {X|Y})
    #   config = Token::Resolver::Config.default
    #   config.pre          # => "{"
    #   config.post         # => "}"
    #   config.separators   # => ["|"]
    #   config.min_segments # => 2
    #
    # @example Custom config (tokens like <<X:Y>>)
    #   config = Token::Resolver::Config.new(
    #     pre: "<<",
    #     post: ">>",
    #     separators: [":"],
    #   )
    #
    # @example Multi-separator config (tokens like {KJ|SECTION:NAME})
    #   config = Token::Resolver::Config.new(
    #     separators: ["|", ":"],
    #   )
    #   # First boundary uses "|", second uses ":", rest repeat ":"
    #
    class Config
      # @return [String] Opening delimiter for tokens
      attr_reader :pre

      # @return [String] Closing delimiter for tokens
      attr_reader :post

      # @return [Array<String>] Separators between segments (used sequentially; last repeats)
      attr_reader :separators

      # @return [Integer] Minimum number of segments for a valid token
      attr_reader :min_segments

      # @return [Integer, nil] Maximum number of segments (nil = unlimited)
      attr_reader :max_segments

      # Create a new Config.
      #
      # @param pre [String] Opening delimiter (default: "{")
      # @param post [String] Closing delimiter (default: "}")
      # @param separators [Array<String>] Segment separators (default: ["|"])
      # @param min_segments [Integer] Minimum segment count (default: 2)
      # @param max_segments [Integer, nil] Maximum segment count (default: nil)
      #
      # @raise [ArgumentError] If any delimiter is empty or constraints are invalid
      def initialize(pre: "{", post: "}", separators: ["|"], min_segments: 2, max_segments: nil)
        validate!(pre, post, separators, min_segments, max_segments)

        @pre = pre.dup.freeze
        @post = post.dup.freeze
        @separators = separators.map { |s| s.dup.freeze }.freeze
        @min_segments = min_segments
        @max_segments = max_segments

        freeze
      end

      class << self
        # Default config suitable for kettle-jem style tokens like {KJ|GEM_NAME}.
        #
        # @return [Config]
        def default
          @default ||= new # rubocop:disable ThreadSafety/ClassInstanceVariable
        end
      end

      # Equality based on all attributes.
      #
      # @param other [Object]
      # @return [Boolean]
      def eql?(other)
        return false unless other.is_a?(Config)

        pre == other.pre &&
          post == other.post &&
          separators == other.separators &&
          min_segments == other.min_segments &&
          max_segments == other.max_segments
      end

      alias_method :==, :eql?

      # Hash based on all attributes (for use as Hash key / grammar cache).
      #
      # @return [Integer]
      def hash
        [pre, post, separators, min_segments, max_segments].hash
      end

      # Get the separator for a given boundary index.
      #
      # When there are more segment boundaries than separators, the last separator repeats.
      #
      # @param index [Integer] Zero-based boundary index
      # @return [String] The separator to use
      def separator_at(index)
        if index < separators.length
          separators[index]
        else
          separators.last
        end
      end

      private

      def validate!(pre, post, separators, min_segments, max_segments)
        raise ArgumentError, "pre must be a non-empty String" unless pre.is_a?(String) && !pre.empty?
        raise ArgumentError, "post must be a non-empty String" unless post.is_a?(String) && !post.empty?
        raise ArgumentError, "separators must be a non-empty Array" unless separators.is_a?(Array) && !separators.empty?

        separators.each_with_index do |sep, i|
          raise ArgumentError, "separators[#{i}] must be a non-empty String" unless sep.is_a?(String) && !sep.empty?
        end

        raise ArgumentError, "min_segments must be a positive Integer" unless min_segments.is_a?(Integer) && min_segments >= 1

        if max_segments
          raise ArgumentError, "max_segments must be a positive Integer" unless max_segments.is_a?(Integer) && max_segments >= 1
          raise ArgumentError, "max_segments (#{max_segments}) must be >= min_segments (#{min_segments})" if max_segments < min_segments
        end
      end
    end
  end
end
