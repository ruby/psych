# -*- coding: utf-8 -*-

require 'minitest/autorun'
require 'psych'
require 'stringio'

module Psych
  class TestEmitter < MiniTest::Unit::TestCase
    def setup
      @out = StringIO.new
      @emitter = Psych::Emitter.new @out
    end

    def test_emit_utf_8
      @emitter.start_stream Psych::Nodes::Stream::UTF8
      @emitter.start_document [], [], false
      @emitter.scalar '日本語', nil, nil, false, true, 1
      @emitter.end_document true
      @emitter.end_stream
      assert_match('日本語', @out.string)
    end

    def test_start_stream_arg_error
      assert_raises(TypeError) do
        @emitter.start_stream 'asdfasdf'
      end
    end

    def test_start_doc_arg_error
      @emitter.start_stream Psych::Nodes::Stream::UTF8

      [
        [nil, [], false],
        [[nil, nil], [], false],
        [[], 'foo', false],
        [[], ['foo'], false],
        [[], [nil,nil], false],
      ].each do |args|
        assert_raises(TypeError) do
          @emitter.start_document *args
        end
      end
    end
  end
end
