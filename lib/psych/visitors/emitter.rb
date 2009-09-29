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
    end
  end
end
