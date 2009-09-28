module Psych
  module Nodes
    class Sequence < Psych::Nodes::Node
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
