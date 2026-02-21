# frozen_string_literal: true

require "parslet"

module Token
  module Resolver
    # Transforms the raw parslet parse tree into Node::Text and Node::Token objects.
    #
    # The grammar produces one `:text` entry per character and `:token` entries
    # with `:seg` captures. This transform converts those into proper node objects
    # and coalesces adjacent Text nodes into single nodes.
    #
    # @example
    #   config = Config.default
    #   tree = Grammar.build(config).new.parse("Hi {KJ|X}!")
    #   nodes = Transform.apply(tree, config)
    #   # => [Node::Text("Hi "), Node::Token(["KJ", "X"]), Node::Text("!")]
    #
    class Transform
      class << self
        # Transform a parslet tree into an array of Text and Token nodes.
        #
        # @param tree [Array<Hash>] Raw parslet parse tree
        # @param config [Config] Token configuration
        # @return [Array<Node::Text, Node::Token>] Coalesced node array
        def apply(tree, config)
          return [] if tree.nil? || (tree.respond_to?(:empty?) && tree.empty?)

          # Convert raw parslet entries to node objects
          raw_nodes = tree.map { |entry| convert_entry(entry, config) }

          # Coalesce adjacent Text nodes
          coalesce(raw_nodes)
        end

        private

        def convert_entry(entry, config)
          if entry.key?(:token)
            convert_token(entry[:token], config)
          elsif entry.key?(:text)
            Node::Text.new(slice_to_s(entry[:text]))
          else
            # Shouldn't happen with our grammar, but be safe
            Node::Text.new(entry.to_s)
          end
        end

        def convert_token(token_data, config)
          # token_data contains :seg captures
          # It can be a single seg hash or an array of seg hashes
          segments = extract_segments(token_data)
          Node::Token.new(segments, config)
        end

        def extract_segments(token_data)
          # Parslet returns different structures depending on repetition:
          # - Single segment match: {:seg => "value"}
          # - Multiple segments: [{:seg => "val1"}, {:seg => "val2"}] or {:seg => [...]}
          case token_data
          when Hash
            if token_data[:seg].is_a?(Array)
              token_data[:seg].map { |s| slice_to_s(s) }
            else
              [slice_to_s(token_data[:seg])]
            end
          when Array
            token_data.flat_map { |item|
              if item.is_a?(Hash) && item.key?(:seg)
                [slice_to_s(item[:seg])]
              else
                [slice_to_s(item)]
              end
            }
          else
            [slice_to_s(token_data)]
          end
        end

        def slice_to_s(value)
          value.to_s
        end

        def coalesce(nodes)
          return nodes if nodes.length <= 1

          nodes.chunk { |node| node.is_a?(Node::Text) }
            .flat_map { |is_text, group|
              if is_text
                combined = group.map(&:content).join
                [Node::Text.new(combined)]
              else
                group
              end
            }
        end
      end
    end
  end
end
