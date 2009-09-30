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
        case o.tag
        when 'tag:yaml.org,2002:null'
          nil
        else
          o.value
        end
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
