module Psych
  module Nodes
    ###
    # This class represents a {YAML Mapping}[http://yaml.org/spec/1.1/#mapping].
    class Mapping < Psych::Nodes::Node
      def initialize anchor, tag, implicit, style
        super()
        @anchor   = anchor
        @tag      = tag
        @implicit = implicit
        @style    = style
      end
    end
  end
end
