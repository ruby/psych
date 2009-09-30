require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestYASTBuilder < MiniTest::Unit::TestCase
      def test_scalar
        v = Visitors::YASTBuilder.new
        v.accept 'foo'

        assert_equal 'foo', Psych.load(v.tree.to_yaml)
      end
    end
  end
end
