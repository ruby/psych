module Psych
  module Nodes
    ###
    # This class represents a {YAML Mapping}[http://yaml.org/spec/1.1/#mapping].
    class Mapping < Psych::Nodes::Node
      # Mapping Styles
      ANY   = 0
      BLOCK = 1
      FLOW  = 2

      # The optional anchor for this mapping
      attr_accessor :anchor

      # The optional tag for this mapping
      attr_accessor :tag

      # Is this an implicit mapping?
      attr_accessor :implicit

      # The style of this mapping
      attr_accessor :style

      def initialize anchor = nil, tag = nil, implicit = true, style = BLOCK
        super()
        @anchor   = anchor
        @tag      = tag
        @implicit = implicit
        @style    = style
      end
    end
  end
end
