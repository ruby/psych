# frozen_string_literal: true
require_relative 'helper'

module Psych
  class TestOmap < TestCase
    def test_parse_as_map
      o = Psych.unsafe_load "--- !!omap\na: 1\nb: 2"
      assert_kind_of Psych::Omap, o
      assert_equal 1, o['a']
      assert_equal 2, o['b']
    end

    def test_self_referential
      map = Psych::Omap.new
      map['foo'] = 'bar'
      map['self'] = map
      assert_equal(map, Psych.unsafe_load(Psych.dump(map)))
    end

    def test_keys
      map = Psych::Omap.new
      map['foo'] = 'bar'
      assert_equal 'bar', map['foo']
    end

    def test_order
      map = Psych::Omap.new
      map['a'] = 'b'
      map['b'] = 'c'
      assert_equal [%w{a b}, %w{b c}], map.to_a
    end

    def test_square
      list = [["a", "b"], ["b", "c"]]
      map = Psych::Omap[*list.flatten]
      assert_equal list, map.to_a
      assert_equal 'b', map['a']
      assert_equal 'c', map['b']
    end

    def test_dump
      map = Psych::Omap['a', 'b', 'c', 'd']
      yaml = Psych.dump(map)
      assert_match('!omap', yaml)
      assert_match('- a: b', yaml)
      assert_match('- c: d', yaml)
    end

    def test_round_trip
      list = [["a", "b"], ["b", "c"]]
      map = Psych::Omap[*list.flatten]
      assert_cycle(map)
    end

    def test_load
      list = [["a", "b"], ["c", "d"]]
      map = Psych.load(<<-eoyml)
--- !omap
- a: b
- c: d
      eoyml
      assert_equal list, map.to_a
    end

    # NOTE: This test will not work with Syck
    def test_load_shorthand
      list = [["a", "b"], ["c", "d"]]
      map = Psych.load(<<-eoyml)
--- !!omap
- a: b
- c: d
      eoyml
      assert_equal list, map.to_a
    end

    # Regression test for OSS-Fuzz crash: malformed omap with scalar children
    # Bug: NoMethodError: undefined method `first' for nil when omap has scalar child
    # The omap processing code assumed all children would be sequences with .children
    # returning an array, but scalar nodes have .children == nil
    def test_oss_fuzz_crash_omap_scalar_child
      # This YAML reproduces the OSS-Fuzz crash found by fuzz_load fuzzer
      # An !omap tag with a bare "-" creates a scalar child instead of sequence
      # When the code tries to access scalar.children.first, it calls nil.first
      yaml = <<~YAML
        ---
        !omap
        -
      YAML
      
      # Use the exact same method as the fuzzer: Psych.safe_load_stream
      # This processes the omap tag and triggers the crash without the fix
      result = Psych.safe_load_stream(yaml)
      assert_kind_of Array, result
      # The omap should be created but empty (malformed entry skipped)
      omap = result.first
      assert_kind_of Hash, omap  # safe_load_stream returns plain Hash, not Omap
      assert_equal 0, omap.size
    end
  end
end
