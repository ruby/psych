module Psych
  module Visitors
    ###
    # This class walks a YAML AST, converting each node to ruby
    class ToRuby < Psych::Visitors::Visitor
      def initialize
        super
        @st = {}
      end

      visitor_for(Nodes::Scalar) do |o|
        @st[o.anchor] = o.value if o.anchor
        o.value
      end

      visitor_for(Nodes::Sequence) do |o|
        o.children.map { |c| c.accept self }
      end

      visitor_for(Nodes::Mapping) do |o|
        Hash[*o.children.map { |c| c.accept self }]
      end

      visitor_for(Nodes::Document) do |o|
        o.root.accept self
      end

      visitor_for(Nodes::Stream) do |o|
        o.children.map { |c| c.accept self }
      end

      visitor_for(Nodes::Alias) do |o|
        @st[o.anchor]
      end
    end
  end
end
