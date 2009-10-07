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

      def visit_Struct o
        tag = ['!ruby/struct', o.class.name].compact.join(':')

        @stack.push append Nodes::Mapping.new(nil, tag, false)
        o.members.each do |member|
          accept member
          accept o[member]
        end
        @stack.pop
      end

      def visit_Exception o
        @stack.push append Nodes::Mapping.new(nil, '!ruby/exception', false)
        ['message', o.message].each do |m|
          accept m
        end
        @stack.pop
      end

      def visit_Regexp o
        append Nodes::Scalar.new(o.inspect, nil, '!ruby/regexp', false)
      end

      def visit_Time o
        formatted = o.strftime("%Y-%m-%d %H:%M:%S")
        if o.utc?
          formatted += ".%06dZ" % [o.usec]
        else
          formatted += ".%06d %d:00" % [o.usec, o.gmt_offset / 3600]
        end

        append Nodes::Scalar.new formatted
      end

      def visit_Date o
        append Nodes::Scalar.new o.to_s
      end

      def visit_Rational o
        @stack.push append Nodes::Mapping.new(nil,'!ruby/object:Rational',false)
        ['denominator', o.denominator, 'numerator', o.numerator].each do |m|
          accept m
        end
        @stack.pop
      end

      def visit_Complex o
        @stack.push append Nodes::Mapping.new(nil, '!ruby/object:Complex', false)
        ['real', o.real, 'image', o.image].each do |m|
          accept m
        end
        @stack.pop
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

      def visit_Range o
        @stack.push append Nodes::Mapping.new(nil, '!ruby/range', false)
        ['begin', o.begin, 'end', o.end, 'excl', o.exclude_end?].each do |m|
          accept m
        end
        @stack.pop
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
          accept k
          accept v
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
        o.each { |c| accept c }
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
