module Psych
  module Visitors
    class YAMLStream < Psych::Visitors::YAMLTree
      class StreamEmitter
        def initialize io
          @handler = Psych::Emitter.new io
          @stack   = []
        end

        def push node
          @stack << node

          case node
          when Psych::Nodes::Mapping  then start_mapping node
          when Psych::Nodes::Sequence then start_sequence node
          when Psych::Nodes::Document then start_document node
          when Psych::Nodes::Stream   then start_stream node
          else
            raise "Can't handle #{node}"
          end
        end
        alias :<< :push

        def pop
          node = @stack.pop

          case node
          when Psych::Nodes::Mapping  then end_mapping node
          when Psych::Nodes::Sequence then end_sequence node
          when Psych::Nodes::Document then end_document node
          when Psych::Nodes::Stream   then end_stream node
          else
            raise "Can't handle #{node}"
          end
        end

        def start_stream o
          @handler.start_stream o.encoding
        end

        def end_stream o
          @handler.end_stream
        end

        def start_document o
          @handler.start_document o.version, o.tag_directives, o.implicit
        end

        def end_document o
          @handler.end_document o.implicit_end
        end

        def start_mapping o
          @handler.start_mapping o.anchor, o.tag, o.implicit, o.style
        end

        def end_mapping o
          @handler.end_mapping
        end

        def start_sequence o
          @handler.start_sequence o.anchor, o.tag, o.implicit, o.style
        end

        def end_sequence o
          @handler.end_sequence
        end

        def scalar value, anchor, tag, plain, quoted, style
          @handler.scalar value, anchor, tag, plain, quoted, style
        end
      end

      def initialize io
        super()
        @stack = StreamEmitter.new io
        @stack << Psych::Nodes::Stream.new
      end

      def << object
        @stack.push create_document
        accept object
        @stack.pop
      end

      def finish
        @stack.pop
      end

      private
      def append o; o end
      def register o, yml; yml end

      def create_scalar value, anchor = nil, tag = nil, plain = true, quoted = false, style = Nodes::Scalar::ANY
        @stack.scalar value, anchor, tag, plain, quoted, style
      end
    end
  end
end
