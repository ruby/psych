require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestToRuby < MiniTest::Unit::TestCase
      def setup
        @visitor = ToRuby.new
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
