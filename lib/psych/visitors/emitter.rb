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
        @handler.end_document o.implicit
      end
    end
  end
end
