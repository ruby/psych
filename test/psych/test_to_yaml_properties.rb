require 'minitest/autorun'
require 'psych'

module Psych
  class TestToYamlProperties < MiniTest::Unit::TestCase
    class Foo
      attr_accessor :a, :b, :c
      def initialize
        @a = 1
        @b = 2
        @c = 3
      end

      def to_yaml_properties
        [:@a, :@b]
      end
    end

    class InitApi < Foo
      attr_accessor :implicit
      attr_accessor :style
      attr_accessor :tag

      def init_with coder
        @a = coder['aa']
        @b = coder['bb']
        @implicit = coder.implicit
        @tag      = coder.tag
        @style    = coder.style
      end

      def encode_with coder
        coder['aa'] = @a
        coder['bb'] = @b
      end
    end

    class TaggingCoder < InitApi
      def encode_with coder
        super
        coder.tag       = coder.tag.sub(/!/, '!hello')
        coder.implicit  = false
        coder.style     = Psych::Nodes::Mapping::FLOW
      end
    end

    def test_load_dumped_tagging
      foo = InitApi.new
      bar = Psych.load(Psych.dump(foo))
      assert_equal false, bar.implicit
      assert_equal "!ruby/object:Psych::TestToYamlProperties::InitApi", bar.tag
      assert_equal Psych::Nodes::Mapping::BLOCK, bar.style
    end

    def test_dump_with_tag
      foo = TaggingCoder.new
      assert_match(/hello/, Psych.dump(foo))
      assert_match(/{aa/, Psych.dump(foo))
    end

    def test_dump_encode_with
      foo = InitApi.new
      assert_match(/aa/, Psych.dump(foo))
    end

    def test_dump_init_with
      foo = InitApi.new
      bar = Psych.load(Psych.dump(foo))
      assert_equal foo.a, bar.a
      assert_equal foo.b, bar.b
      assert_nil bar.c
    end

    def test_object_dump_yaml_properties
      foo = Psych.load(Psych.dump(Foo.new))
      assert_equal 1, foo.a
      assert_equal 2, foo.b
      assert_nil foo.c
    end

    class Bar < Struct.new(:foo, :bar)
      attr_reader :baz
      def initialize *args
        super
        @baz = 'hello'
      end

      def to_yaml_properties
        []
      end
    end

    def test_struct_dump_yaml_properties
      bar = Psych.load(Psych.dump(Bar.new('a', 'b')))
      assert_equal 'a', bar.foo
      assert_equal 'b', bar.bar
      assert_nil bar.baz
    end

    def test_string_dump
      string = "okonomiyaki"
      class << string
        def to_yaml_properties
          [:@tastes]
        end
      end

      string.instance_variable_set(:@tastes, 'delicious')
      v = Psych.load Psych.dump string
      assert_equal 'delicious', v.instance_variable_get(:@tastes)
    end

    def test_string_load_syck
      str = Psych.load("--- !str \nstr: okonomiyaki\n:@tastes: delicious\n")
      assert_equal 'okonomiyaki', str
      assert_equal 'delicious', str.instance_variable_get(:@tastes)
    end
  end
end
