# frozen_string_literal: true

require "parslet"

module Token
  module Resolver
    # Dynamically builds a Parslet::Parser subclass from a Config.
    #
    # The grammar recognizes structured tokens (e.g., `{KJ|GEM_NAME}`) within
    # arbitrary text. It is designed to **never fail** — any input is valid.
    # Unrecognized content (including incomplete tokens) becomes text nodes.
    #
    # @example Building and using a grammar
    #   parser_class = Token::Resolver::Grammar.build(Config.default)
    #   tree = parser_class.new.parse("Hello {KJ|NAME}!")
    #   # => [{:text=>"H"@0}, {:text=>"e"@1}, ..., {:token=>{:segments=>[...]}}, ...]
    #
    # @note The raw parslet tree contains one :text entry per character.
    #   Use Transform to coalesce these into proper Text nodes.
    #
    class Grammar
      # Cache of built parser classes, keyed by Config.
      # Config is frozen and implements #hash/#eql?, so this is safe.
      @cache = {}
      @cache_mutex = Mutex.new

      class << self
        # Build (or retrieve from cache) a Parslet::Parser subclass for the given Config.
        #
        # @param config [Config] Token configuration
        # @return [Class] A Parslet::Parser subclass
        def build(config)
          @cache_mutex.synchronize do
            @cache[config] ||= build_parser_class(config)
          end
        end

        # Clear the grammar cache. Mostly useful for testing.
        #
        # @return [void]
        def clear_cache!
          @cache_mutex.synchronize do
            @cache.clear
          end
        end

        private

        def build_parser_class(config)
          pre_str = config.pre
          post_str = config.post
          separators = config.separators
          min_segs = config.min_segments
          max_segs = config.max_segments

          Class.new(Parslet::Parser) do
            # A segment is one or more characters that are not a separator or post delimiter.
            # We need to exclude ALL separators and the post delimiter.
            define_method(:_config) { config }

            # Build the set of strings that terminate a segment
            terminators = ([post_str] + separators).uniq

            # segment: one or more chars that aren't any terminator
            rule(:segment) {
              terminator_absent = terminators.map { |t| str(t).absent? }.reduce(:>>)
              (terminator_absent >> any).repeat(1)
            }

            # token: pre + segment + (sep + segment).repeat + post
            # with min/max segment constraints
            rule(:token) {
              # Build the repeating part: (separator + segment)
              # For sequential separators, we'd need to handle them specially.
              # However, parslet rules are declarative, so we handle sequential seps
              # by building a chain: first_sep >> segment >> second_sep >> segment >> ...
              # For the general case with repeating last separator, we use a dynamic approach.

              # Simple case: build "pre segment (sep segment)* post" and validate segment count after
              # We use the first separator for the first boundary, second for the second, etc.
              # Last separator repeats.

              # For parslet, we need to build this statically. The simplest approach:
              # Match pre + segment + (any_sep + segment)* + post, capture all segments,
              # then validate count in the Transform step.

              # Build alternation of all separators
              sep_match = if separators.length == 1
                str(separators[0])
              else
                separators.map { |s| str(s) }.reduce(:|)
              end

              base = str(pre_str) >>
                segment.as(:seg) >>
                (sep_match >> segment.as(:seg)).repeat(min_segs - 1, max_segs ? max_segs - 1 : nil) >>
                str(post_str)

              base
            }

            # text_char: any single character that doesn't start a valid token
            rule(:text_char) {
              # If we see pre_str, try to match a token. If it fails, consume pre_str as text.
              # Parslet's ordered choice handles this: token is tried first in document.
              # Here we just need to match any single character.
              any
            }

            # document: sequence of tokens and text characters
            rule(:document) {
              (token.as(:token) | text_char.as(:text)).repeat
            }

            root(:document)
          end
        end
      end
    end
  end
end
