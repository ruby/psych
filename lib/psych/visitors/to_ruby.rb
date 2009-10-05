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
        return Complex(o.value) if o.tag == "!ruby/object:Complex"
        return o.value if o.quoted

        token = ScalarScanner.new(o.value).tokenize

        case token.first
        when :DATE
          require 'date'
          Date.strptime token.last, '%Y-%m-%d'
        else
          token.last
        end
      end

      def visit_Psych_Nodes_Sequence o
        list = []
        @st[o.anchor] = list if o.anchor
        o.children.each { |c| list.push accept c }
        list
      end

      def visit_Psych_Nodes_Mapping o
        case o.tag
        when '!ruby/range'
          h = Hash[*o.children.map { |c| accept c }]
          Range.new(h['begin'], h['end'], h['excl'])

        when '!ruby/object:Complex'
          h = Hash[*o.children.map { |c| accept c }]
          Complex(h['real'], h['image'])

        when '!ruby/object:Rational'
          h = Hash[*o.children.map { |c| accept c }]
          Rational(h['numerator'], h['denominator'])

        else
          hash = {}
          @st[o.anchor] = hash if o.anchor
          o.children.map { |c| accept c }.each_slice(2) { |k,v|
            hash[k] = v
          }
          hash
        end
      end

      def visit_Psych_Nodes_Document o
        accept o.root
      end

      def visit_Psych_Nodes_Stream o
        o.children.map { |c| accept c }
      end

      def visit_Psych_Nodes_Alias o
        @st[o.anchor]
      end
    end
  end
end
