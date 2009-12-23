module Psych
  module Visitors
    class Visitor
      YAML_NODE_DISPATCH_TABLE = Hash[
        *Nodes.constants.map { |k|
          k = Nodes.const_get k
          [k, :"visit_#{k.name.split('::').join('_')}"]
        }.flatten
      ]

      def accept target
        send(YAML_NODE_DISPATCH_TABLE[target.class], target)
      end
    end
  end
end
