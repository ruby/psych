require 'test/psych/helper'

module Psych
  class TestObjectToYaml < TestCase
    def test_object_has_to_yaml
      o = Object.new
      assert o.respond_to?(:to_yaml)
      assert_equal o.method(:psych_to_yaml), o.method(:to_yaml)

      # Put the method back where we found it!
      if o.respond_to?(:old_to_yaml)
        Object.send :remove_method, :to_yaml
        Object.send :alias_method, :to_yaml, :old_to_yaml
      end
    end
  end
end
