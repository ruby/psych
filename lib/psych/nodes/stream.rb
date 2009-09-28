module Psych
  module Nodes
    ###
    # Represents a YAML stream.  This is the root node for any YAML parse
    # tree.
    class Stream < Psych::Nodes::Node
      attr_reader :encoding
      def initialize encoding
        super()
        @encoding = encoding
      end
    end
  end
end
