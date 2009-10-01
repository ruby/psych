require 'psych/scalar_scanner'

module Psych
  module Visitors
    ###
    # This class walks a YAML AST, converting each node to ruby
    class ToRuby < Psych::Visitors::Visitor
      def initialize
        super
        @st = {}
      end

      def visit_Psych_Nodes_Scalar o
        @st[o.anchor] = o.value if o.anchor

        return o.value if ['!str', 'tag:yaml.org,2002:str'].include?(o.tag)
        return o.value if o.quoted

        return ScalarScanner.new(o.value).tokenize.last
      end

      def visit_Psych_Nodes_Sequence o
        list = []
        @st[o.anchor] = list if o.anchor
        o.children.each { |c| list.push c.accept self }
        list
      end

      def visit_Psych_Nodes_Mapping o
        case o.tag
        when 'ruby/range'
          h = Hash[*o.children.map { |c| c.accept self }]
          Range.new(h['begin'], h['end'], h['excl'])
        else
          hash = {}
          @st[o.anchor] = hash if o.anchor
          o.children.map { |c| c.accept self }.each_slice(2) { |k,v|
            hash[k] = v
          }
          hash
        end
      end

      def visit_Psych_Nodes_Document o
        o.root.accept self
      end

      def visit_Psych_Nodes_Stream o
        o.children.map { |c| c.accept self }
      end

      def visit_Psych_Nodes_Alias o
        @st[o.anchor]
      end
    end
  end
end
