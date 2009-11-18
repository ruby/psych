require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestYAMLTree < MiniTest::Unit::TestCase
      def setup
        @v = Visitors::YAMLTree.new
      end

      def test_object_has_no_class
        yaml = Psych.dump(Object.new)
        assert(Psych.dump(Object.new) !~ /Object/, yaml)
      end

      def test_struct_const
        foo = Struct.new("Foo", :bar)
        assert_round_trip foo.new('bar')
      end

      A = Struct.new(:foo)

      def test_struct
        assert_round_trip A.new('bar')
      end

      def test_struct_anon
        s = Struct.new(:foo).new('bar')
        obj =  Psych.load(Psych.dump(s))
        assert_equal s.foo, obj.foo
      end

      def test_exception
        ex = Exception.new 'foo'
        loaded = Psych.load(Psych.dump(ex))

        assert_equal ex.message, loaded.message
        assert_equal ex.class, loaded.class
      end

      def test_regexp
        assert_round_trip(/foo/)
        assert_round_trip(/foo/i)
        assert_round_trip(/foo/mx)
      end

      def test_time
        assert_round_trip Time.now
      end

      def test_date
        date = Date.strptime('2002-12-14', '%Y-%m-%d')
        assert_round_trip date
      end

      def test_rational
        assert_round_trip Rational(1,2)
      end

      def test_complex
        assert_round_trip Complex(1,2)
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
        assert_round_trip ':'
      end

      def test_boolean
        assert_round_trip true
        assert_round_trip 'true'
        assert_round_trip false
        assert_round_trip 'false'
      end

      def test_range_inclusive
        assert_round_trip 1..2
      end

      def test_range_exclusive
        assert_round_trip 1...2
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
        v = Visitors::YAMLTree.new
        v.accept(obj)
        assert_equal(obj, Psych.load(v.tree.to_yaml))
        assert_equal(obj, Psych.load(obj.to_yaml))
        assert_equal(obj, Psych.load(Psych.dump(obj)))
      end
    end
  end
end
