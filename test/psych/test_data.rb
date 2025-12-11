# frozen_string_literal: true
require_relative 'helper'

PsychData = Data.define(:foo) unless RUBY_VERSION < "3.2"

module Psych
  class TestData < TestCase
    def setup
      omit "Data requires ruby >= 3.2" if RUBY_VERSION < "3.2"
    end

    # TODO: move to another test?
    def test_dump_data
      assert_equal <<~eoyml, Psych.dump(PsychData["bar"])
        --- !ruby/data:PsychData
        foo: bar
      eoyml
    end

    def test_roundtrip
      thing = PsychData.new("bar")
      data = Psych.unsafe_load(Psych.dump(thing))

      assert_equal "bar",   data.foo
    end

    def test_load
      obj = Psych.unsafe_load(<<~eoyml)
        --- !ruby/data:PsychData
        foo: bar
      eoyml

      assert_equal "bar",   obj.foo
    end
  end
end

