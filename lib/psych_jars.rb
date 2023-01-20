# frozen_string_literal: true
require 'psych.jar'

require 'jar-dependencies'
require_jar('org.snakeyaml', 'snakeyaml-engine', Psych::DEFAULT_SNAKEYAML_VERSION)
