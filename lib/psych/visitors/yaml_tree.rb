module Psych
  module Visitors
    class YAMLTree < Psych::Visitors::Visitor
      attr_reader :tree

      def initialize options = {}
        super()
        @tree = Nodes::Stream.new
        @tree.children << Nodes::Document.new
        @stack = @tree.children.dup
        @st = {}
      end

      def accept target
        # return any aliases we find
        if node = @st[target.object_id]
          node.anchor = target.object_id.to_s
          return append Nodes::Alias.new target.object_id.to_s
        end

        target.class.ancestors.each do |klass|
          next unless klass.name
          method_name = :"visit_#{klass.name.split('::').join('_')}"

          return send(method_name, target) if respond_to?(method_name)

        end
        raise TypeError, "Can't dump #{target.class}"
      end

      def visit_Psych_Set o
        map = Nodes::Mapping.new(nil, '!set', false)
        @st[o.object_id] = map

        @stack.push append map

        o.each do |k,v|
          accept k
          accept v
        end

        @stack.pop
      end

      def visit_Psych_Omap o
        seq = Nodes::Sequence.new(nil, '!omap', false)
        @st[o.object_id] = seq

        @stack.push append seq
        o.each do |k,v|
          accept k => v
        end
        @stack.pop
      end

      def visit_Object o
        klass = o.class == Object ? nil : o.class.name
        tag = ['!ruby/object', klass].compact.join(':')

        mapping = Nodes::Mapping.new(nil, tag, false)
        @stack.push append mapping

        if o.respond_to? :to_yaml_properties
          ivars = o.to_yaml_properties
        else
          ivars = o.instance_variables
        end

        ivars.each do |iv|
          mapping.children << Nodes::Scalar.new(":#{iv.to_s.sub(/^@/, '')}")
          accept o.instance_variable_get(iv)
        end
        @stack.pop
      end

      def visit_Struct o
        tag = ['!ruby/struct', o.class.name].compact.join(':')

        map = Nodes::Mapping.new(nil, tag, false)
        @st[o.object_id] = map

        @stack.push append map
        o.members.each do |member|
          accept member
          accept o[member]
        end

        if o.respond_to? :to_yaml_properties
          ivars = o.to_yaml_properties
        else
          ivars = o.instance_variables
        end

        ivars.each do |iv|
          map.children << Nodes::Scalar.new(":#{iv.to_s.sub(/^@/, '')}")
          accept o.instance_variable_get(iv)
        end
        @stack.pop
      end

      def visit_Exception o
        tag = ['!ruby/exception', o.class.name].join ':'

        mapping = Nodes::Mapping.new(nil, tag, false)
        @stack.push append mapping

        {
          'message'   => private_iv_get(o, 'mesg'),
          'backtrace' => private_iv_get(o, 'backtrace'),
        }.each do |k,v|
          next unless v
          append Nodes::Scalar.new k
          accept v
        end

        if o.respond_to? :to_yaml_properties
          ivars = o.to_yaml_properties
        else
          ivars = o.instance_variables
        end

        ivars.each do |iv|
          mapping.children << Nodes::Scalar.new(":#{iv.to_s.sub(/^@/, '')}")
          accept o.instance_variable_get(iv)
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
        plain = false
        quote = false

        if o.index("\x00") || o.count("^ -~\t\r\n").fdiv(o.length) > 0.3
          str   = [o].pack('m').chomp
          tag   = '!binary'
        else
          str   = o
          tag   = nil
          quote = ScalarScanner.new(o).tokenize.first != :SCALAR
          plain = !quote
        end


        if o.respond_to? :to_yaml_properties
          ivars = o.to_yaml_properties
        else
          ivars = o.instance_variables
        end

        scalar = Nodes::Scalar.new str, nil, tag, plain, quote

        if ivars.empty?
          append scalar
        else
          mapping = append Nodes::Mapping.new(nil, '!str', false)

          mapping.children << Nodes::Scalar.new('str')
          mapping.children << scalar

          @stack.push mapping
          ivars.each do |iv|
            mapping.children << Nodes::Scalar.new(":#{iv}")
            accept o.instance_variable_get(iv)
          end
          @stack.pop
        end
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
