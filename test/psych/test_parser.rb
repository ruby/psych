require 'helper'

module Psych
  class TestParser < Test::Unit::TestCase
    class EventCatcher < Parser::Handler
      attr_reader :calls
      def initialize
        @calls = []
      end

      (Parser::Handler.instance_methods(true) -
       Object.instance_methods).each do |m|
        class_eval %{
          def #{m} *args
            super
            @calls << [:#{m}, args]
          end
        }
      end
    end

    def setup
      warn "#{name}" if ENV['TESTOPTS'] == '-v'
      @parser = Psych::Parser.new EventCatcher.new
    end

    def test_sequence_end
      @parser.parse("---\n&A [1, 2]")
      assert_called :end_sequence
    end

    def test_sequence_start_anchor
      @parser.parse("---\n&A [1, 2]")
      assert_called :start_sequence, ["A", true, FLOW_SEQUENCE_STYLE]
    end

    def test_sequence_start_tag
      @parser.parse("---\n!!seq [1, 2]")
      assert_called :start_sequence, ["tag:yaml.org,2002:seq", false, FLOW_SEQUENCE_STYLE]
    end

    def test_sequence_start_flow
      @parser.parse("---\n[1, 2]")
      assert_called :start_sequence, [true, FLOW_SEQUENCE_STYLE]
    end

    def test_sequence_start_block
      @parser.parse("---\n  - 1\n  - 2")
      assert_called :start_sequence, [true, BLOCK_SEQUENCE_STYLE]
    end

    def test_literal_scalar
      @parser.parse(<<-eoyml)
%YAML 1.1
---
"literal\n\
        \ttext\n"
      eoyml
      assert_called :scalar, ['literal text ', false, true, 3]
    end

    def test_scalar
      @parser.parse("--- foo\n")
      assert_called :scalar, ['foo', true, false, 1]
    end

    def test_scalar_with_tag
      @parser.parse("---\n!!str foo\n")
      assert_called :scalar, ['foo', 'tag:yaml.org,2002:str', false, false, 1]
    end

    def test_scalar_with_anchor
      @parser.parse("---\n&A foo\n")
      assert_called :scalar, ['foo', 'A', true, false, 1]
    end

    def test_scalar_plain_implicit
      @parser.parse("---\n&A foo\n")
      assert_called :scalar, ['foo', 'A', true, false, 1]
    end

    def test_alias
      @parser.parse(<<-eoyml)
%YAML 1.1
---
!!seq [
  !!str "Without properties",
  &A !!str "Anchored",
  !!str "Tagged",
  *A,
  !!str "",
]
      eoyml
      assert_called :alias, ['A']
    end

    def test_end_stream
      @parser.parse("--- foo\n")
      assert_called :end_stream
    end

    def test_start_stream
      @parser.parse("--- foo\n")
      assert_called :start_stream
    end

    def test_end_document_implicit
      @parser.parse("\"foo\"\n")
      assert_called :end_document, [true]
    end

    def test_end_document_explicit
      @parser.parse("\"foo\"\n...")
      assert_called :end_document, [false]
    end

    def test_start_document_version
      @parser.parse("%YAML 1.1\n---\n\"foo\"\n")
      assert_called :start_document, [[1,1], [], false]
    end

    def test_start_document_tag
      @parser.parse("%TAG !yaml! tag:yaml.org,2002\n---\n!yaml!str \"foo\"\n")
      assert_called :start_document, [[], [['!yaml!', 'tag:yaml.org,2002']], false]
    end

    def assert_called call, with = nil, parser = @parser
      if with
        call = parser.handler.calls.find { |x|
          x.first == call && x.last.compact == with
        }
        assert(call,
          "#{[call,with].inspect} not in #{parser.handler.calls.inspect}"
        )
      else
        assert parser.handler.calls.any? { |x| x.first == call }
      end
    end
  end
end
