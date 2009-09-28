module Psych
  module Visitors
    class Visitor
      def self.visitor_for *klasses, &block
        klasses.each do |klass|
          method_name = klass.name.split('::').join('_')
          define_method(:"visit_#{method_name}", block)
        end
      end

      def accept target
        method_name = target.class.name.split('::').join('_')
        send(:"visit_#{method_name}", target)
      end
    end
  end
end
