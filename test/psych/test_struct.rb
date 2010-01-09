require 'minitest/autorun'
require 'psych'

module Psych
  class TestStruct < MiniTest::Unit::TestCase
    class StructSubclass < Struct.new(:foo)
      def initialize foo, bar
        super(foo)
        @bar = bar
      end
    end

    def test_self_referential_struct
      ss = StructSubclass.new(nil, 'foo')
      ss.foo = ss

      loaded = Psych.load(Psych.dump(ss))
      assert_instance_of(StructSubclass, loaded.foo)

      # FIXME: This seems to cause an infinite loop.  wtf.  Must report a bug
      # in ruby.
      # assert_equal(ss, loaded)
    end
  end
end
