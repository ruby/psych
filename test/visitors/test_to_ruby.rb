require 'minitest/autorun'
require 'psych'
require 'complex'
require 'date'
require 'rational'

module Psych
  module Visitors
    class TestToRuby < MiniTest::Unit::TestCase
      def setup
        @visitor = ToRuby.new
      end

      A = Struct.new(:foo)

      def test_struct
        s = A.new('bar')

        mapping = Nodes::Mapping.new nil, "!ruby/struct:#{s.class}"
        mapping.children << Nodes::Scalar.new('foo')
        mapping.children << Nodes::Scalar.new('bar')

        ruby = mapping.to_ruby

        assert_equal s.class, ruby.class
        assert_equal s.foo, ruby.foo
        assert_equal s, ruby
      end

      def test_anon_struct_legacy
        s = Struct.new(:foo).new('bar')

        mapping = Nodes::Mapping.new nil, '!ruby/struct:'
        mapping.children << Nodes::Scalar.new('foo')
        mapping.children << Nodes::Scalar.new('bar')

        assert_equal s.foo, mapping.to_ruby.foo
      end

      def test_anon_struct
        s = Struct.new(:foo).new('bar')

        mapping = Nodes::Mapping.new nil, '!ruby/struct'
        mapping.children << Nodes::Scalar.new('foo')
        mapping.children << Nodes::Scalar.new('bar')

        assert_equal s.foo, mapping.to_ruby.foo
      end

      def test_exception
        exc = Exception.new 'hello'

        mapping = Nodes::Mapping.new nil, '!ruby/exception'
        mapping.children << Nodes::Scalar.new('message')
        mapping.children << Nodes::Scalar.new('hello')

        ruby = mapping.to_ruby

        assert_equal exc.class, ruby.class
        assert_equal exc.message, ruby.message
      end

      def test_regexp
        node = Nodes::Scalar.new('/foo/', nil, '!ruby/regexp')
        assert_equal(/foo/, node.to_ruby)

        node = Nodes::Scalar.new('/foo/m', nil, '!ruby/regexp')
        assert_equal(/foo/m, node.to_ruby)

        node = Nodes::Scalar.new('/foo/ix', nil, '!ruby/regexp')
        assert_equal(/foo/ix, node.to_ruby)
      end

      def test_time
        now = Time.now
        formatted = now.strftime("%Y-%m-%d %H:%M:%S") +
          ".%06d %d:00" % [now.usec, now.gmt_offset / 3600]

        assert_equal now, Nodes::Scalar.new(formatted).to_ruby
      end

      def test_time_utc
        now = Time.now.utc
        formatted = now.strftime("%Y-%m-%d %H:%M:%S") +
          ".%06dZ" % [now.usec]

        assert_equal now, Nodes::Scalar.new(formatted).to_ruby
      end

      def test_time_utc_no_z
        now = Time.now.utc
        formatted = now.strftime("%Y-%m-%d %H:%M:%S") +
          ".%06d" % [now.usec]

        assert_equal now, Nodes::Scalar.new(formatted).to_ruby
      end

      def test_date
        d = '1980-12-16'
        actual = Date.strptime(d, '%Y-%m-%d')

        date = Nodes::Scalar.new(d, nil, 'tag:yaml.org,2002:timestamp', false)

        assert_equal actual, date.to_ruby
      end

      def test_rational
        mapping = Nodes::Mapping.new nil, '!ruby/object:Rational'
        mapping.children << Nodes::Scalar.new('denominator')
        mapping.children << Nodes::Scalar.new('2')
        mapping.children << Nodes::Scalar.new('numerator')
        mapping.children << Nodes::Scalar.new('1')

        assert_equal Rational(1,2), mapping.to_ruby
      end

      def test_complex
        mapping = Nodes::Mapping.new nil, '!ruby/object:Complex'
        mapping.children << Nodes::Scalar.new('image')
        mapping.children << Nodes::Scalar.new('2')
        mapping.children << Nodes::Scalar.new('real')
        mapping.children << Nodes::Scalar.new('1')

        assert_equal Complex(1,2), mapping.to_ruby
      end

      if RUBY_VERSION >= '1.9'
        def test_complex_string
          node = Nodes::Scalar.new '3+4i', nil, "!ruby/object:Complex"
          assert_equal Complex(3, 4), node.to_ruby
        end

        def test_rational_string
          node = Nodes::Scalar.new '1/2', nil, "!ruby/object:Rational"
          assert_equal Rational(1, 2), node.to_ruby
        end
      end

      def test_range_string
        node = Nodes::Scalar.new '1..2', nil, "!ruby/range"
        assert_equal 1..2, node.to_ruby
      end

      def test_range_string_triple
        node = Nodes::Scalar.new '1...3', nil, "!ruby/range"
        assert_equal 1...3, node.to_ruby
      end

      def test_integer
        i = Nodes::Scalar.new('1', nil, 'tag:yaml.org,2002:int')
        assert_equal 1, i.to_ruby

        assert_equal 1, Nodes::Scalar.new('1').to_ruby

        i = Nodes::Scalar.new('-1', nil, 'tag:yaml.org,2002:int')
        assert_equal(-1, i.to_ruby)

        assert_equal(-1, Nodes::Scalar.new('-1').to_ruby)
        assert_equal 1, Nodes::Scalar.new('+1').to_ruby
      end

      def test_int_ignore
        ['1,000', '1_000'].each do |num|
          i = Nodes::Scalar.new(num, nil, 'tag:yaml.org,2002:int')
          assert_equal 1000, i.to_ruby

          assert_equal 1000, Nodes::Scalar.new(num).to_ruby
        end
      end

      def test_float_ignore
        ['1,000.3', '1_000.3'].each do |num|
          i = Nodes::Scalar.new(num, nil, 'tag:yaml.org,2002:float')
          assert_equal 1000.3, i.to_ruby

          assert_equal 1000.3, Nodes::Scalar.new(num).to_ruby
        end
      end

      # http://yaml.org/type/bool.html
      def test_boolean_true
        %w{ y Y yes Yes YES true True TRUE on On ON }.each do |t|
          i = Nodes::Scalar.new(t, nil, 'tag:yaml.org,2002:bool')
          assert_equal true, i.to_ruby
          assert_equal true, Nodes::Scalar.new(t).to_ruby
        end
      end

      # http://yaml.org/type/bool.html
      def test_boolean_false
        %w{ n N no No NO false False FALSE off Off OFF }.each do |t|
          i = Nodes::Scalar.new(t, nil, 'tag:yaml.org,2002:bool')
          assert_equal false, i.to_ruby
          assert_equal false, Nodes::Scalar.new(t).to_ruby
        end
      end

      def test_float
        i = Nodes::Scalar.new('1.2', nil, 'tag:yaml.org,2002:float')
        assert_equal 1.2, i.to_ruby

        i = Nodes::Scalar.new('1.2')
        assert_equal 1.2, i.to_ruby

        assert_equal 1, Nodes::Scalar.new('.Inf').to_ruby.infinite?
        assert_equal 1, Nodes::Scalar.new('.inf').to_ruby.infinite?
        assert_equal 1, Nodes::Scalar.new('.Inf', nil, 'tag:yaml.org,2002:float').to_ruby.infinite?

        assert_equal(-1, Nodes::Scalar.new('-.inf').to_ruby.infinite?)
        assert_equal(-1, Nodes::Scalar.new('-.Inf').to_ruby.infinite?)
        assert_equal(-1, Nodes::Scalar.new('-.Inf', nil, 'tag:yaml.org,2002:float').to_ruby.infinite?)

        assert Nodes::Scalar.new('.NaN').to_ruby.nan?
        assert Nodes::Scalar.new('.NaN', nil, 'tag:yaml.org,2002:float').to_ruby.nan?
      end

      def test_exp_float
        exp = 1.2e+30

        i = Nodes::Scalar.new(exp.to_s, nil, 'tag:yaml.org,2002:float')
        assert_equal exp, i.to_ruby

        assert_equal exp, Nodes::Scalar.new(exp.to_s).to_ruby
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

      def test_mapping
        mapping = Nodes::Mapping.new
        mapping.children << Nodes::Scalar.new('foo')
        mapping.children << Nodes::Scalar.new('bar')
        assert_equal({'foo' => 'bar'}, mapping.to_ruby)
      end

      def test_document
        doc = Nodes::Document.new
        doc.children << Nodes::Scalar.new('foo')
        assert_equal 'foo', doc.to_ruby
      end

      def test_stream
        a = Nodes::Document.new
        a.children << Nodes::Scalar.new('foo')

        b = Nodes::Document.new
        b.children << Nodes::Scalar.new('bar')

        stream = Nodes::Stream.new
        stream.children << a
        stream.children << b

        assert_equal %w{ foo bar }, stream.to_ruby
      end

      def test_alias
        seq = Nodes::Sequence.new
        seq.children << Nodes::Scalar.new('foo', 'A')
        seq.children << Nodes::Alias.new('A')

        list = seq.to_ruby
        assert_equal %w{ foo foo }, list
        assert_equal list[0].object_id, list[1].object_id
      end
    end
  end
end
