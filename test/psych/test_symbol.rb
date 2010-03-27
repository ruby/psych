require 'minitest/autorun'
require 'psych'

module Psych
  class TestSymbol < MiniTest::Unit::TestCase
    def test_to_yaml
      assert_equal :a, Psych.load(:a.to_yaml)
    end

    def test_dump
      assert_equal :a, Psych.load(Psych.dump(:a))
    end

    def test_stringy
      assert_equal :"1", Psych.load(Psych.dump(:"1"))
    end

    def test_load_quoted
      assert_equal :"1", Psych.load("--- :'1'\n")
    end
  end
end
