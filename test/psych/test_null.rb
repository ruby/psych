require 'minitest/autorun'
require 'psych'

module Psych
  ###
  # Test null from YAML spec:
  # http://yaml.org/type/null.html
  class TestNull < MiniTest::Unit::TestCase
    def test_null_list
      assert_equal [nil] * 5, Psych.load(<<-eoyml)
---
- ~
- null
- 
- Null
- NULL
      eoyml
    end
  end
end
