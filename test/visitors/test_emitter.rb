require 'minitest/autorun'
require 'psych'

module Psych
  module Visitors
    class TestEmitter < MiniTest::Unit::TestCase
      def setup
        @io = StringIO.new
        @visitor = Visitors::Emitter.new @io
      end

      def test_stream
        s = Nodes::Stream.new
        @visitor.accept s
        assert_equal '', @io.string
      end

      def test_document
        s = Nodes::Stream.new
        s.children << Nodes::Document.new([1,1])
        @visitor.accept s
        assert_equal '', @io.string
      end
    end
  end
end
