module Psych
  module Nodes
    ###
    # This class represents a {YAML Scalar}[http://yaml.org/spec/1.1/#id858081].
    class Scalar < Psych::Nodes::Node
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

      def initialize value, anchor, tag, plain, quoted, style
        super()
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
