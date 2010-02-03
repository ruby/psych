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
        @ss = ScalarScanner.new

        @dispatch_cache = Hash.new do |h,klass|
          method = "visit_#{(klass.name || '').split('::').join('_')}"

          method = respond_to?(method) ? method : h[klass.superclass]

          raise(TypeError, "Can't dump #{target.class}") unless method

          h[klass] = method
        end
      end

      def accept target
        # return any aliases we find
        if node = @st[target.object_id]
          node.anchor = target.object_id.to_s
          return append Nodes::Alias.new target.object_id.to_s
        end

        if target.respond_to?(:encode_with)
          dump_coder target
        else
          send(@dispatch_cache[target.class], target)
        end
      end

      def visit_Psych_Omap o
        seq = Nodes::Sequence.new(nil, '!omap', false)
        register(o, seq)

        @stack.push append seq
        o.each { |k,v| visit_Hash k => v }
        @stack.pop
      end

      def visit_Object o
        tag = Psych.dump_tags[o.class]
        unless tag
          klass = o.class == Object ? nil : o.class.name
          tag   = ['!ruby/object', klass].compact.join(':')
        end

        map = append Nodes::Mapping.new(nil, tag, false)

        @stack.push map
        dump_ivars(o, map)
        @stack.pop
      end

      def visit_Struct o
        tag = ['!ruby/struct', o.class.name].compact.join(':')

        map = register(o, Nodes::Mapping.new(nil, tag, false))

        @stack.push append map

        o.members.each do |member|
          map.children <<  Nodes::Scalar.new(":#{member}")
          accept o[member]
        end

        dump_ivars(o, map)

        @stack.pop
      end

      def visit_Exception o
        tag = ['!ruby/exception', o.class.name].join ':'

        map = append Nodes::Mapping.new(nil, tag, false)

        @stack.push map

        {
          'message'   => private_iv_get(o, 'mesg'),
          'backtrace' => private_iv_get(o, 'backtrace'),
        }.each do |k,v|
          next unless v
          map.children << Nodes::Scalar.new(k)
          accept v
        end

        dump_ivars(o, map)

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

      def visit_Rational o
        map = append Nodes::Mapping.new(nil, '!ruby/object:Rational', false)
        [
          'denominator', o.denominator.to_s,
          'numerator', o.numerator.to_s
        ].each do |m|
          map.children << Nodes::Scalar.new(m)
        end
      end

      def visit_Complex o
        map = append Nodes::Mapping.new(nil, '!ruby/object:Complex', false)

        ['real', o.real.to_s, 'image', o.image.to_s].each do |m|
          map.children << Nodes::Scalar.new(m)
        end
      end

      def visit_Integer o
        append Nodes::Scalar.new o.to_s
      end
      alias :visit_TrueClass :visit_Integer
      alias :visit_FalseClass :visit_Integer
      alias :visit_Date :visit_Integer

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
          quote = !(String === @ss.tokenize(o))
          plain = !quote
        end

        ivars = o.respond_to?(:to_yaml_properties) ?
          o.to_yaml_properties :
          o.instance_variables

        scalar = Nodes::Scalar.new str, nil, tag, plain, quote

        if ivars.empty?
          append scalar
        else
          mapping = append Nodes::Mapping.new(nil, '!str', false)

          mapping.children << Nodes::Scalar.new('str')
          mapping.children << scalar

          @stack.push mapping
          dump_ivars o, mapping
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
        @stack.push append register(o, Nodes::Mapping.new)

        o.each do |k,v|
          accept k
          accept v
        end

        @stack.pop
      end

      def visit_Psych_Set o
        @stack.push append register(o, Nodes::Mapping.new(nil, '!set', false))

        o.each do |k,v|
          accept k
          accept v
        end

        @stack.pop
      end

      def visit_Array o
        @stack.push append register(o, Nodes::Sequence.new)
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

      def register target, yaml_obj
        @st[target.object_id] = yaml_obj
        yaml_obj
      end

      def dump_coder o
        tag = Psych.dump_tags[o.class]
        unless tag
          klass = o.class == Object ? nil : o.class.name
          tag   = ['!ruby/object', klass].compact.join(':')
        end

        c = Psych::Coder.new(tag)
        o.encode_with(c)
        emit_coder c
      end

      def emit_coder c
        case c.type
        when :scalar
          append Nodes::Scalar.new(c.scalar, nil, c.tag, c.tag.nil?)
        when :map
          map = append Nodes::Mapping.new(nil, c.tag, c.implicit, c.style)
          @stack.push map
          c.map.each do |k,v|
            map.children << Nodes::Scalar.new(k)
            accept v
          end
          @stack.pop
        end
      end

      def dump_ivars target, map
        ivars = target.respond_to?(:to_yaml_properties) ?
          target.to_yaml_properties :
          target.instance_variables

        ivars.each do |iv|
          map.children << Nodes::Scalar.new("#{iv.to_s.sub(/^@/, '')}")
          accept target.instance_variable_get(iv)
        end
      end
    end
  end
end
