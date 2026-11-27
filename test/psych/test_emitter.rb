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

    def test_tag_directives_survive_gc
      # Non UTF-8 handles and prefixes are exported to new Strings that
      # nothing else references.
      tags = (0...8).map { |i|
        c = ("a".ord + i).chr
        ["!#{c * 98}!".encode(Encoding::ISO_8859_1),
         "tag:example.com,2026:#{c * 79}".encode(Encoding::ISO_8859_1)]
      }
      expected = tags.map { |handle, prefix| "%TAG #{handle} #{prefix}\n" }.join

      @emitter.start_stream Psych::Nodes::Stream::UTF8
      stress = GC.stress
      begin
        GC.stress = true
        @emitter.start_document [], tags, false
      ensure
        GC.stress = stress
      end
      @emitter.scalar "v", nil, nil, true, false, Nodes::Scalar::ANY
      @emitter.end_document false
      @emitter.end_stream

      assert_equal expected, @out.string.lines.grep(/\A%TAG/).join
    end

    def test_tag_directives_survive_compaction
      omit "compaction is not supported" unless GC.respond_to?(:verify_compaction_references)
      omit "the libfyaml emitter does not copy tag directives" if libfyaml?

      # The second handle compacts the heap while it is converted, after the
      # first directive has been recorded.
      window = Object.new
      def window.to_str
        GC.verify_compaction_references(expand_heap: true, toward: :empty)
        "!w!"
      end
      # Built in a block so that no local variable pins the Strings.
      tags = 1.times.map {
        ["!" + "a" * 98 + "!", "tag:example.com,2026:" + "p" * 79]
      }
      tags << [window, "tag:example.com,2026:w"]
      expected = "%TAG !#{"a" * 98}! tag:example.com,2026:#{"p" * 79}\n" \
                 "%TAG !w! tag:example.com,2026:w\n"

      @emitter.start_stream Psych::Nodes::Stream::UTF8
      @emitter.start_document [], tags, false
      @emitter.scalar "v", nil, nil, true, false, Nodes::Scalar::ANY
      @emitter.end_document false
      @emitter.end_stream

      assert_equal expected, @out.string.lines.grep(/\A%TAG/).join
    end
  end
end
