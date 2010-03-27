require 'minitest/autorun'
require 'psych'

module Psych
  class TestSet < MiniTest::Unit::TestCase
    def setup
      @set = Psych::Set.new
      @set['foo'] = 'bar'
      @set['bar'] = 'baz'
    end

    def test_to_yaml
      assert_match(/!set/, @set.to_yaml)
    end

    def test_roundtrip
      assert_equal(@set, Psych.load(Psych.dump(@set)))
    end

    ###
    # FIXME: Syck should also support !!set as shorthand
    def test_load_from_yaml
      loaded = Psych.load(<<-eoyml)
--- !set
foo: bar
bar: baz
      eoyml
      assert_equal(@set, loaded)
    end

    def test_loaded_class
      assert_instance_of(Psych::Set, Psych.load(Psych.dump(@set)))
    end

    def test_set_shorthand
      loaded = Psych.load(<<-eoyml)
--- !!set
foo: bar
bar: baz
      eoyml
      assert_instance_of(Psych::Set, loaded)
    end

    def test_set_self_reference
      @set['self'] = @set
      assert_equal(@set, Psych.load(Psych.dump(@set)))
    end
  end
end
