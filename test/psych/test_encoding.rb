# -*- coding: utf-8 -*-

require 'minitest/autorun'
require 'psych'

module Psych
  class TestEncoding < MiniTest::Unit::TestCase
    class EncodingCatcher < Handler
      attr_reader :strings
      def initialize
        @strings = []
      end

      (Handler.instance_methods(true) -
       Object.instance_methods).each do |m|
        class_eval %{
          def #{m} *args
            @strings += args.flatten.find_all { |a|
              String === a
            }
          end
        }
      end
    end

    def setup
      super
      @handler = EncodingCatcher.new
      @parser  = Psych::Parser.new @handler
      @utf8    = Encoding.find('UTF-8')
    end

    def test_scalar
      @parser.parse("--- a")
      assert_encodings @utf8, @handler.strings
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
      assert_encodings @utf8, @handler.strings
    end

    def test_list_anchor
      list = %w{ a b }
      list << list
      @parser.parse(Psych.dump(list))
      assert_encodings @utf8, @handler.strings
    end

    private
    def assert_encodings encoding, strings
      strings.each do |str|
        assert_equal encoding, str.encoding, str
      end
    end
  end
end
