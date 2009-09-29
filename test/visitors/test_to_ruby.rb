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
