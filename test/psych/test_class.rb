require 'test/psych/helper'

module Psych
  class TestClass < TestCase
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
