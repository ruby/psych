require 'psych/parser'
require 'psych/psych'

module Psych
  VERSION         = '1.0.0'
  LIBYAML_VERSION = Psych.libyaml_version.join '.'

  # Encodings supported by Psych (and libyaml)
  ANY_ENCODING      = 1
  UTF8_ENCODING     = 2
  UTF16LE_ENCODING  = 3
  UTF16BE_ENCODING  = 4

  def self.parse thing
    Psych::Parser.new.parse thing
  end
end
