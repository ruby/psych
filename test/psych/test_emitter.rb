# -*- coding: utf-8 -*-
# frozen_string_literal: true

require_relative 'helper'

module Psych
  class TestEmitter < TestCase
    def setup
      super
      @out = StringIO.new(''.dup)
      @emitter = Psych::Emitter.new @out
    end

    def test_line_width
      @emitter.line_width = 10
      assert_equal 10, @emitter.line_width
    end

    def test_set_canonical
      if libfyaml?
        # The libfyaml backend has no canonical mode and rejects enabling it.
        assert_raise(NotImplementedError) { @emitter.canonical = true }
        @emitter.canonical = false
        assert_equal false, @emitter.canonical
        return
      end

      @emitter.canonical = true
      assert_equal true, @emitter.canonical

      @emitter.canonical = false
      assert_equal false, @emitter.canonical
    end

    def test_indentation_set
      assert_equal 2, @emitter.indentation
      @emitter.indentation = 5
      assert_equal 5, @emitter.indentation
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
      assert_raise(TypeError) do
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
        [[1,1], [[nil, "tag:TALOS"]], 0],
      ].each do |args|
        assert_raise(TypeError) do
          @emitter.start_document(*args)
        end
      end
    end

    def test_scalar_arg_error
      @emitter.start_stream Psych::Nodes::Stream::UTF8
      @emitter.start_document [], [], false

      [
        [:foo, nil, nil, false, true, 1],
        ['foo', Object.new, nil, false, true, 1],
        ['foo', nil, Object.new, false, true, 1],
        ['foo', nil, nil, false, true, :foo],
        [nil, nil, nil, false, true, 1],
      ].each do |args|
        assert_raise(TypeError) do
          @emitter.scalar(*args)
        end
      end
    end

    def test_start_sequence_arg_error
      @emitter.start_stream Psych::Nodes::Stream::UTF8
      @emitter.start_document [], [], false

      assert_raise(TypeError) do
        @emitter.start_sequence(nil, Object.new, true, 1)
      end

      assert_raise(TypeError) do
        @emitter.start_sequence(nil, nil, true, :foo)
      end
    end

    def test_invalid_event
      omit 'libyaml backend only' unless libyaml?

      invalid = "\xFF"

      bad_calls = [
        ->(e) { e.scalar(invalid, nil, nil, false, true, 1) },
        ->(e) { e.scalar('x', invalid, nil, false, true, 1) },
        ->(e) { e.scalar('x', nil, invalid, false, true, 1) },
        ->(e) { e.start_sequence(invalid, nil, false, 1) },
        ->(e) { e.start_sequence(nil, invalid, false, 1) },
        ->(e) { e.start_mapping(invalid, nil, false, 1) },
        ->(e) { e.start_mapping(nil, invalid, false, 1) },
        ->(e) { e.alias(invalid) },
      ]

      bad_calls.each do |bad_call|
        out = StringIO.new(''.dup)
        emitter = Psych::Emitter.new out
        emitter.start_stream Psych::Nodes::Stream::UTF8
        emitter.start_document [], [], true
        # Emit a valid event that allocates memory (its anchor and tag).
        emitter.start_sequence 'anchor', 'tag:example.com,2000:seq', false, 1

        assert_raise(RuntimeError) { bad_call.call(emitter) }
      end
    end

    def test_invalid_tag_directive
      omit 'libyaml backend only' unless libyaml?

      invalid = "\xFF"

      @emitter.start_stream Psych::Nodes::Stream::UTF8
      assert_raise(RuntimeError) do
        @emitter.start_document [1, 1], [[invalid, 'tag:x']], false
      end
    end

    def test_resizing_tags
      @emitter.start_stream Psych::Nodes::Stream::UTF8

      tags = []
      version = [1,1]
      obj = Object.new
      obj.instance_variable_set(:@tags, tags)
      def obj.to_str
        (1..10).map{|x| @tags.push(["AAAA","BBBB"])}
        return "x"
      end

      tags.push([obj, "tag:TALOS"])
      @emitter.start_document(version, tags, 0)
      assert(true)
    end
  end
end
