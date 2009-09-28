require 'psych/handler'

module Psych
  ###
  # This class builds an in-memory parse tree tree that represents a YAML
  # document.
  #
  # See Psych::Handler for documentation on the event methods used in this
  # class.
  class TreeBuilder < Psych::Handler
    def initialize
      @stack = []
    end

    def root
      @stack.first
    end

    def start_stream encoding
      super
      @stack.push Nodes::Stream.new encoding
    end

    def start_document version = [], tag_directives = [], implicit = true
      super
      doc = Nodes::Document.new version, tag_directives, implicit
      @stack.last.children << doc
      @stack.push doc
    end

    def start_sequence anchor = nil, tag = nil, implicit = true, style = BLOCK_SEQUENCE_STYLE
      super
      seq = Nodes::Sequence.new anchor, tag, implicit, style
      @stack.last.children << seq
      @stack.push seq
    end
  end
end
