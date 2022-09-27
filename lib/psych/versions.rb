# frozen_string_literal: true

module Psych
  # The version of Psych you are using
  VERSION = '4.0.6'

  if RUBY_ENGINE == 'jruby'
    DEFAULT_SNAKEYAML_VERSION = '1.33'.freeze
  end
end
