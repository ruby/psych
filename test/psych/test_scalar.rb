# -*- coding: utf-8 -*-

require 'minitest/autorun'
require 'psych'

module Psych
  class TestScalar < MiniTest::Unit::TestCase
    def test_utf_8
      assert_equal "日本語", Psych.load("--- 日本語")
    end
  end
end
