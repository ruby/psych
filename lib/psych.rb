require 'psych/visitable'

require 'psych/nodes/node'
require 'psych/nodes/stream'
require 'psych/nodes/document'
require 'psych/nodes/sequence'
require 'psych/nodes/scalar'
require 'psych/nodes/mapping'
require 'psych/nodes/alias'

require 'psych/visitors'

require 'psych/handler'
require 'psych/tree_builder'
require 'psych/parser'
require 'psych/psych'

module Psych
  VERSION         = '1.0.0'
  LIBYAML_VERSION = Psych.libyaml_version.join '.'

  def self.parse thing
    Psych::Parser.new.parse thing
  end
end
