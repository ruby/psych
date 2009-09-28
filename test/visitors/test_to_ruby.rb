require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestToRuby < MiniTest::Unit::TestCase
      def setup
        @visitor = ToRuby.new
      end

      def test_scalar
        scalar = Nodes::Scalar.new('foo')
        assert_equal 'foo', @visitor.accept(scalar)
        assert_equal 'foo', scalar.to_ruby
      end
    end
  end
end
