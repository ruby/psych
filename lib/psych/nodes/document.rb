module Psych
  module Nodes
    class Document < Psych::Nodes::Node
      # The version of the YAML document
      attr_accessor :version

      # A list of tag directives for this document
      attr_accessor :tag_directives

      # Was this document implicitly created?
      attr_accessor :implicit

      def initialize version = [], tag_directives = [], implicit = true
        super()
        @version        = version
        @tag_directives = tag_directives
        @implicit       = implicit
      end

      ###
      # Returns the root node.  A Document may only have one root node:
      # http://yaml.org/spec/1.1/#id898031
      def root
        children.first
      end
    end
  end
end
