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
      @parser = Psych::Parser.new EventCatcher.new
    end

    def test_end_stream
      @parser.parse("--- foo\n")
      assert_called :end_stream
    end

    def test_start_stream
      @parser.parse("--- foo\n")
      assert_called :start_stream
    end

    def test_start_document
      @parser.parse("%YAML 1.1\n---\n\"foo\"\n")
      assert_called :start_document, [[1,1]]
    end

    def assert_called call, with = nil, parser = @parser
      if with
        assert parser.handler.calls.any? { |x| x == [call, with] }
      else
        assert parser.handler.calls.any? { |x| x.first == call }
      end
    end
  end
end
