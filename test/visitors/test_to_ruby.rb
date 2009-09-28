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

      def test_sequence
        seq = Nodes::Sequence.new
        seq.children << Nodes::Scalar.new('foo')
        seq.children << Nodes::Scalar.new('bar')

        assert_equal %w{ foo bar }, seq.to_ruby
      end
    end
  end
end
