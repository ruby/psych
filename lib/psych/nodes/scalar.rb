module Psych
  module Nodes
    ###
    # This class represents a {YAML Scalar}[http://yaml.org/spec/1.1/#id858081].
    class Scalar < Psych::Nodes::Node
      # Scalar Styles
      ANY           = 0
      PLAIN         = 1
      SINGLE_QUOTED = 2
      DOUBLE_QUOTED = 3
      LITERAL       = 4
      FOLDED        = 5

      # The scalar value
      attr_accessor :value

      # The anchor value (if there is one)
      attr_accessor :anchor

      # The tag value (if there is one)
      attr_accessor :tag

      # Is this a plain scalar?
      attr_accessor :plain

      # Is this scalar quoted?
      attr_accessor :quoted

      # The style of this scalar
      attr_accessor :style

      def initialize value, anchor = nil, tag = nil, plain = true, quoted = false, style = ANY
        @value  = value
        @anchor = anchor
        @tag    = tag
        @plain  = plain
        @quoted = quoted
        @style  = style
      end
    end
  end
end
