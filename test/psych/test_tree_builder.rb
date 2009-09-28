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
  end
end
