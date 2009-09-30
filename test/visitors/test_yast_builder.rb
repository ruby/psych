require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestYASTBuilder < MiniTest::Unit::TestCase
      def test_scalar
        v = Visitors::YASTBuilder.new
        v.accept 'foo'

        assert_equal 'foo', Psych.load(v.tree.to_yaml)
        assert_equal 'foo', Psych.load('foo'.to_yaml)
      end

      def test_binary
        string = [0, 123,22, 44, 9, 32, 34, 39].pack('C*')
        assert_equal string, Psych.load(string.to_yaml)
      end
    end
  end
end
