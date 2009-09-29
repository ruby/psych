module Psych
  module Visitors
    class Emitter < Psych::Visitors::Visitor
      def initialize io
        @handler = Psych::Emitter.new io
      end

      visitor_for(Nodes::Stream) do |o|
        @handler.start_stream o.encoding
        o.children.each { |c| c.accept self }
        @handler.end_stream
      end

      visitor_for(Nodes::Document) do |o|
        @handler.start_document o.version, o.tag_directives, o.implicit
        o.children.each { |c| c.accept self }
        @handler.end_document o.implicit_end
      end

      visitor_for(Nodes::Scalar) do |o|
        @handler.scalar o.value, o.anchor, o.tag, o.plain, o.quoted, o.style
      end

      visitor_for(Nodes::Sequence) do |o|
        @handler.start_sequence o.anchor, o.tag, o.implicit, o.style
        o.children.each { |c| c.accept self }
        @handler.end_sequence
      end

      visitor_for(Nodes::Mapping) do |o|
        @handler.start_mapping o.anchor, o.tag, o.implicit, o.style
        o.children.each { |c| c.accept self }
        @handler.end_mapping
      end
    end
  end
end
