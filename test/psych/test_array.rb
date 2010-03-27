require 'minitest/autorun'
require 'psych'

module Psych
  class TestArray < MiniTest::Unit::TestCase
    def setup
      @list = [{ :a => 'b' }, 'foo']
    end

    def test_self_referential
      @list << @list
      assert_equal @list, Psych.load(@list.to_yaml)
    end

    def test_to_yaml
      assert_equal @list, Psych.load(@list.to_yaml)
    end

    def test_dump
      assert_equal @list, Psych.load(Psych.dump(@list))
    end
  end
end
