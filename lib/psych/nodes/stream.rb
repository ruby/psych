module Psych
  module Nodes
    ###
    # Represents a YAML stream.  This is the root node for any YAML parse
    # tree.
    class Stream < Psych::Nodes::Node

      # Encodings supported by Psych (and libyaml)
      ANY     = 0
      UTF8    = 1
      UTF16LE = 2
      UTF16BE = 3

      # The encoding used for this stream
      attr_reader :encoding

      def initialize encoding = UTF8
        super()
        @encoding = encoding
      end
    end
  end
end
