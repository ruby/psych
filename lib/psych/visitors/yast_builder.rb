module Psych
  module Visitors
    class YASTBuilder < Psych::Visitors::Visitor
      attr_reader :tree

      def initialize options = {}
        super()
        @tree = Nodes::Stream.new
        @tree.children << Nodes::Document.new
        @stack = @tree.children.dup
        @st = {}
      end

      def accept target
        target.class.ancestors.each do |klass|
          method_name = :"visit_#{klass.name.split('::').join('_')}"
          if respond_to?(method_name)
            return send(method_name, target)
          end
        end
        raise TypeError, "Can't dump #{target.class}"
      end

      def visit_Integer o
        append Nodes::Scalar.new o.to_s
      end

      def visit_TrueClass o
        append Nodes::Scalar.new o.to_s
      end

      def visit_FalseClass o
        append Nodes::Scalar.new o.to_s
      end

      def visit_Float o
        if o.nan?
          append Nodes::Scalar.new '.nan'
        elsif o.infinite?
          append Nodes::Scalar.new(o.infinite? > 0 ? '.inf' : '-.inf')
        else
          append Nodes::Scalar.new o.to_s
        end
      end

      def visit_String o
        quote = ScalarScanner.new(o).tokenize.first != :SCALAR

        scalar = Nodes::Scalar.new(o, nil, nil, !quote, quote)
        @stack.last.children << scalar
      end

      def visit_Class o
        raise TypeError, "can't dump anonymous class #{o.class}"
      end

      def visit_Hash o
        if node = @st[o.object_id]
          node.anchor = o.object_id.to_s
          return append Nodes::Alias.new o.object_id.to_s
        end

        map = Nodes::Mapping.new
        @st[o.object_id] = map

        @stack.push append map

        o.each do |k,v|
          k.accept self
          v.accept self
        end

        @stack.pop
      end

      def visit_Array o
        if node = @st[o.object_id]
          node.anchor = o.object_id.to_s
          return append Nodes::Alias.new o.object_id.to_s
        end

        seq = Nodes::Sequence.new
        @st[o.object_id] = seq

        @stack.push append seq
        o.each { |c| c.accept self }
        @stack.pop
      end

      def visit_NilClass o
        append Nodes::Scalar.new('', nil, 'tag:yaml.org,2002:null', false)
      end

      def visit_Symbol o
        append Nodes::Scalar.new ":#{o}"
      end

      private
      def append o
        @stack.last.children << o
        o
      end
    end
  end
end
