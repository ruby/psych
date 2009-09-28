require 'helper'

module Psych
  module Visitors
    class TestToRuby < Test::Unit::TestCase
      def setup
        @visitor = ToRuby.new
      end

      def test_scalar
        scalar = Nodes::Scalar.new('foo')
        assert_equal 'foo', @visitor.accept(scalar)
      end
    end
  end
end
