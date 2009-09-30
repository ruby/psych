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

      def test_hash
        assert_round_trip('a' => 'b')
      end

      def test_list
        assert_round_trip(%w{ a b })
      end

      # http://yaml.org/type/null.html
      def test_nil
        assert_round_trip nil
        assert_equal nil, Psych.load('null')
        assert_equal nil, Psych.load('Null')
        assert_equal nil, Psych.load('NULL')
        assert_equal nil, Psych.load('~')
        assert_equal({'foo' => nil}, Psych.load('foo: '))

        assert_round_trip 'null'
        assert_round_trip 'nUll'
        assert_round_trip '~'
      end

      def assert_round_trip obj
        v = Visitors::YASTBuilder.new
        v.accept(obj)
        assert_equal(obj, Psych.load(v.tree.to_yaml))
        assert_equal(obj, Psych.load(obj.to_yaml))
        assert_equal(obj, Psych.load(Psych.dump(obj)))
      end
    end
  end
end
