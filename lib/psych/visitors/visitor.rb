module Psych
  module Visitors
    class Visitor
      def accept target
        method_name = target.class.name.split('::').join('_')
        send(:"visit_#{method_name}", target)
      end
    end
  end
end
