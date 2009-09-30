require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestYASTBuilder < MiniTest::Unit::TestCase
      def setup
        @v = Visitors::YASTBuilder.new
      end
      def test_scalar
        @v.accept 'foo'

        assert_equal 'foo', Psych.load(@v.tree.to_yaml)
        assert_equal 'foo', Psych.load('foo'.to_yaml)
      end

      def test_binary
        string = [0, 123,22, 44, 9, 32, 34, 39].pack('C*')
        assert_equal string, Psych.load(string.to_yaml)
      end

      def test_anon_class
        assert_raises(TypeError) do
          @v.accept Class.new
        end

        assert_raises(TypeError) do
          Class.new.to_yaml
        end
      end
    end
  end
end
