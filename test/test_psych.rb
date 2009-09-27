require 'helper'

class TestPsych < Test::Unit::TestCase
  def test_simple
    assert_equal 'foo', Psych.parse("--- foo\n")
  end

  def test_libyaml_version
    assert Psych.libyaml_version
    assert_equal Psych.libyaml_version.join('.'), Psych::LIBYAML_VERSION
  end
end
