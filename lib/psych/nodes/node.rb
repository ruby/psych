module Psych
  module Nodes
    ###
    # The base class for any Node in a YAML parse tree.  This class should
    # never be instantiated.
    class Node
      include Psych::Visitable

      attr_reader :children

      def initialize
        @children = []
      end
    end
  end
end
