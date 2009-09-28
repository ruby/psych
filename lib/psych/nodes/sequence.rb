module Psych
  module Nodes
    ###
    # This class represents a
    # {YAML sequence}[http://yaml.org/spec/1.1/#sequence/syntax].
    #
    # A YAML sequence is basically a list, and looks like this:
    #
    #   %YAML 1.1
    #   ---
    #   - I am
    #   - a Sequence
    #
    # A YAML sequence may have an anchor like this:
    #
    #   %YAML 1.1
    #   ---
    #   &A [
    #     "This sequence",
    #     "has an anchor"
    #   ]
    #
    # A YAML sequence may also have a tag like this:
    #
    #   %YAML 1.1
    #   ---
    #   !!seq [
    #     "This sequence",
    #     "has a tag"
    #   ]
    #
    class Sequence < Psych::Nodes::Node
      # The anchor for this sequence (if any)
      attr_accessor :anchor

      # The tag name for this sequence (if any)
      attr_accessor :tag

      # Is this sequence started implicitly?
      attr_accessor :implicit

      # The sequece style used
      attr_accessor :style

      def initialize anchor, tag, implicit, style
        super()
        @anchor   = anchor
        @tag      = tag
        @implicit = implicit
        @style    = style
      end
    end
  end
end
