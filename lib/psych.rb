require 'psych/nodes/node'
require 'psych/nodes/stream'
require 'psych/nodes/document'
require 'psych/nodes/sequence'
require 'psych/nodes/scalar'
require 'psych/nodes/mapping'
require 'psych/nodes/alias'

require 'psych/handler'
require 'psych/tree_builder'
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

  # Scalar Styles
  ANY_SCALAR_STYLE            = 0
  PLAIN_SCALAR_STYLE          = 1
  SINGLE_QUOTED_SCALAR_STYLE  = 2
  DOUBLE_QUOTED_SCALAR_STYLE  = 3
  LITERAL_SCALAR_STYLE        = 4
  FOLDED_SCALAR_STYLE         = 5

  # Sequence Styles
  ANY_SEQUENCE_STYLE    = 0
  BLOCK_SEQUENCE_STYLE  = 1
  FLOW_SEQUENCE_STYLE   = 2

  # Mapping Styles
  ANY_MAPPING_STYLE   = 0
  BLOCK_MAPPING_STYLE = 1
  FLOW_MAPPING_STYLE  = 2

  def self.parse thing
    Psych::Parser.new.parse thing
  end
end
