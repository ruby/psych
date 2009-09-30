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

  ###
  # Load +yaml+ in to a Ruby data structure
  def self.load yaml
    parse(yaml).to_ruby
  end

  def self.parse yaml
    parser = Psych::Parser.new(TreeBuilder.new)
    parser.parse yaml
    parser.handler.root.children.first.children.first
  end
end
