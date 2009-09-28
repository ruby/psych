module Psych
  module Nodes
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
