require_relative '../helper'

module Psych
  module Visitors
    class TestDepthFirst < TestCase
      def test_scalar
        collector = Class.new(Struct.new(:calls)) {
          def initialize(calls = [])
            super
          end

          def call obj
            calls << obj
          end
        }.new
        visitor = Visitors::DepthFirst.new collector
        visitor.accept Psych.parse '--- hello'

        assert_equal 3, collector.calls.length
      end
    end
  end
end
