module Psych
  module Nodes
    ###
    # Represents a YAML stream.  This is the root node for any YAML parse
    # tree.
    class Stream < Psych::Nodes::Node

      # Encodings supported by Psych (and libyaml)
      ANY     = Psych::Parser::ANY
      UTF8    = Psych::Parser::UTF8
      UTF16LE = Psych::Parser::UTF16LE
      UTF16BE = Psych::Parser::UTF16BE

      # The encoding used for this stream
      attr_reader :encoding

      def initialize encoding = UTF8
        super()
        @encoding = encoding
      end
    end
  end
end
