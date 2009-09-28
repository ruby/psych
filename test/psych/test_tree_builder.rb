require 'helper'

module Psych
  class TestTreeBuilder < Test::Unit::TestCase
    def setup
      @parser = Psych::Parser.new TreeBuilder.new
      @parser.parse(<<-eoyml)
%YAML 1.1
---
- foo
- {
  bar : &A !!str baz,
  boo : *A
}
- baz
      eoyml
      @tree = @parser.handler.root
    end

    def test_stream
      assert_instance_of Nodes::Stream, @tree
    end

    def test_documents
      assert_equal 1, @tree.children.length
      assert_instance_of Nodes::Document, @tree.children.first
      doc = @tree.children.first

      assert_equal [1,1], doc.version
      assert_equal [], doc.tag_directives
      assert_equal false, doc.implicit
    end

    def test_sequence
      doc = @tree.children.first
      assert_equal 1, doc.children.length

      seq = doc.children.first
      assert_instance_of Nodes::Sequence, seq
      assert_nil seq.anchor
      assert_nil seq.tag
      assert_equal true, seq.implicit
      assert_equal BLOCK_SEQUENCE_STYLE, seq.style
    end

    def test_scalar
      doc = @tree.children.first
      seq = doc.children.first

      assert_equal 3, seq.children.length
      scalar = seq.children.first
      assert_instance_of Nodes::Scalar, scalar
      assert_equal 'foo', scalar.value
      assert_nil scalar.anchor
      assert_nil scalar.tag
      assert_equal true, scalar.plain
      assert_equal false, scalar.quoted
      assert_equal PLAIN_SCALAR_STYLE, scalar.style
    end

    def test_mapping
      doc = @tree.children.first
      seq = doc.children.first
      map = seq.children[1]

      assert_instance_of Nodes::Mapping, map
    end
  end
end
