require 'minitest/autorun'
require 'psych'

module Psych
  class TestSerializeSubclasses < MiniTest::Unit::TestCase
    class SomeObject
      def initialize one, two
        @one = one
        @two = two
      end

      def == other
        @one == other.instance_eval { @one } &&
          @two == other.instance_eval { @two }
      end
    end

    def test_some_object
      so = SomeObject.new('foo', [1,2,3])
      assert_equal so, Psych.load(Psych.dump(so))
    end
  end
end
