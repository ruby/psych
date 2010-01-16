module Psych
  module Visitors
    class Visitor
      def accept target
        case target
        when Psych::Nodes::Scalar
          visit_Psych_Nodes_Scalar target
        when Psych::Nodes::Mapping
          visit_Psych_Nodes_Mapping target
        when Psych::Nodes::Sequence
          visit_Psych_Nodes_Sequence target
        when Psych::Nodes::Document
          visit_Psych_Nodes_Document target
        when Psych::Nodes::Stream
          visit_Psych_Nodes_Stream target
        when Psych::Nodes::Alias
          visit_Psych_Nodes_Alias target
        else
          raise "Can't handle #{target}"
        end
      end
    end
  end
end
