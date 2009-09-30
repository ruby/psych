module Psych
  module Visitors
    class YASTBuilder < Psych::Visitors::Visitor
      attr_reader :tree

      def initialize options = {}
        super()
        @tree = Nodes::Stream.new
        @tree.children << Nodes::Document.new
        @stack = @tree.children.dup
      end

      def accept target
        target.class.ancestors.each do |klass|
          method_name = :"visit_#{target.class.name.split('::').join('_')}"
          if respond_to?(method_name)
            return send(method_name, target)
          end
        end
        raise TypeError, "Can't dump #{target.class}"
      end

      visitor_for(::String) do |o|
        @stack.last.children << Nodes::Scalar.new(o)
      end

      visitor_for(::Class) do |o|
        raise TypeError, "can't dump anonymous class #{o.class}"
      end

      visitor_for(::Hash) do |o|
        map = Nodes::Mapping.new
        @stack.last.children << map
        @stack.push map

        o.each do |k,v|
          k.accept self
          v.accept self
        end

        @stack.pop
      end
    end
  end
end
