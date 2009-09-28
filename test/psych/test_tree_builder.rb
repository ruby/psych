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
    end
  end
end
