module Psych
  module Nodes
    class Document < Psych::Nodes::Node
      def initialize version, tag_directives, implicit
        super()
        @version        = version
        @tag_directives = tag_directives
        @implicit       = implicit
      end
    end
  end
end
