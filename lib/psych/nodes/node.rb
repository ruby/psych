require 'stringio'

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

      def to_ruby
        Visitors::ToRuby.new.accept self
      end

      def to_yaml
        io = StringIO.new
        Visitors::Emitter.new(io).accept self
        io.string
      end
    end
  end
end
