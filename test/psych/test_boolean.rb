# frozen_string_literal: true
require_relative 'helper'

module Psych
  ###
  # Test booleans from YAML spec:
  # http://yaml.org/type/bool.html
  class TestBoolean < TestCase
    %w{ y Y yes Yes YES true True TRUE on On ON }.each do |truth|
      define_method(:"test_#{truth}") do
        assert_equal true, Psych.load("--- #{truth}")
      end
    end

    %w{ n N no No NO false False FALSE off Off OFF }.each do |truth|
      define_method(:"test_#{truth}") do
        assert_equal false, Psych.load("--- #{truth}")
      end
    end

    ###
    # A quoted 'y' string should load as a string (not +true+).
    # A 'y' string should dump a quoted string (not +true+).
    # A non-quoted +y+ should load/dump as +true+.
    #
    # This is incompatible with Ruby's original Syck library,
    # but compatible with YAML spec v1.1.
    def test_y_str
      assert_equal "y", Psych.load("--- 'y'")
      assert_equal "Y", Psych.load("--- 'Y'")
      assert_equal "--- 'y'\n", Psych.dump('y')
      assert_equal "--- 'Y'\n", Psych.dump('Y')
    end

    ###
    # A quoted 'n' string should load as a string (not +false+).
    # An 'n' string should dump a quoted string (not +false+).
    # A non-quoted +n+ should load/dump as +false+.
    #
    # This is incompatible with Ruby's original Syck library,
    # but compatible with YAML spec v1.1.
    def test_n_str
      assert_equal "n", Psych.load("--- 'n'")
      assert_equal "N", Psych.load("--- 'N'")
      assert_equal "--- 'n'\n", Psych.dump('n')
      assert_equal "--- 'N'\n", Psych.dump('N')
    end
  end
end
