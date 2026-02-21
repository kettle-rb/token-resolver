# frozen_string_literal: true

module Token
  module Resolver
    # Namespace for node types produced by parsing.
    module Node
      autoload :Text, "token/resolver/node/text"
      autoload :Token, "token/resolver/node/token"
    end
  end
end
