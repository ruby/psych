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
        raise "Can't handle #{target.class}"
      end

      visitor_for(::String) do |o|
        @stack.last.children << Nodes::Scalar.new(o)
      end
    end
  end
end
