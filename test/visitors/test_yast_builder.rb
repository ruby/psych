require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestYASTBuilder < MiniTest::Unit::TestCase
      def setup
        @v = Visitors::YASTBuilder.new
      end

      def test_circular_list
        a = []
        2.times { a << a }
        assert_equal a.inspect, Psych.load(a.to_yaml).inspect
      end

      def test_circular_map
        a = {}
        a[a] = a
        assert_equal a.inspect, Psych.load(a.to_yaml).inspect
      end

      def test_scalar
        assert_round_trip 'foo'
        assert_round_trip ':foo'
        assert_round_trip ''
      end

      def test_boolean
        assert_round_trip true
        assert_round_trip 'true'
        assert_round_trip false
        assert_round_trip 'false'
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
        assert_round_trip([1, 2.2])
      end

      def test_symbol
        assert_round_trip :foo
      end

      def test_int
        assert_round_trip 1
        assert_round_trip(-1)
        assert_round_trip '1'
        assert_round_trip '-1'
      end

      def test_float
        assert_round_trip 1.2
        assert_round_trip '1.2'

        assert Psych.load(Psych.dump(0.0 / 0.0)).nan?
        assert_equal 1, Psych.load(Psych.dump(1 / 0.0)).infinite?
        assert_equal(-1, Psych.load(Psych.dump(-1 / 0.0)).infinite?)
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
