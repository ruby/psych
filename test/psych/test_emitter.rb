# -*- coding: utf-8 -*-

require 'minitest/autorun'
require 'psych'
require 'stringio'

module Psych
  class TestEmitter < MiniTest::Unit::TestCase
    def test_emit_utf_8
      out = StringIO.new
      emitter = Psych::Emitter.new out
      emitter.start_stream Psych::Nodes::Stream::UTF8
      emitter.start_document [], [], false
      emitter.scalar '日本語', nil, nil, false, true, 1
      emitter.end_document true
      emitter.end_stream
      assert_match('日本語', out.string)
    end
  end
end
