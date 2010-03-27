require 'minitest/autorun'
require 'psych'

module Psych
  class TestClass < MiniTest::Unit::TestCase
    def test_to_yaml
      assert_raises(::TypeError) do
        TestClass.to_yaml
      end
    end

    def test_dump
      assert_raises(::TypeError) do
        Psych.dump TestClass
      end
    end
  end
end
