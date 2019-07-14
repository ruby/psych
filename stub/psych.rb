# frozen_string_literal: true

# This file is only on $LOAD_PATH when using a binary gem

require "#{RUBY_VERSION[/\d+\.\d+/]}/psych.so"
require_relative '../lib/psych'
