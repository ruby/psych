module Psych
  module Nodes
    ###
    # This class represents a {YAML Alias}[http://yaml.org/spec/1.1/#alias].
    # It points to an +anchor+
    class Alias < Psych::Nodes::Node
      # The anchor this alias links to
      attr_accessor :anchor

      def initialize anchor
        @anchor = anchor
      end
    end
  end
end
