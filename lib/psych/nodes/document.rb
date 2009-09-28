module Psych
  module Nodes
    class Document < Psych::Nodes::Node
      # The version of the YAML document
      attr_accessor :version

      # A list of tag directives for this document
      attr_accessor :tag_directives

      # Was this document implicitly created?
      attr_accessor :implicit

      def initialize version, tag_directives, implicit
        super()
        @version        = version
        @tag_directives = tag_directives
        @implicit       = implicit
      end
    end
  end
end
