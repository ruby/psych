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
      @stack.push Nodes::Stream.new encoding
    end

    def start_document version = [], tag_directives = [], implicit = true
      doc = Nodes::Document.new version, tag_directives, implicit
      @stack.last.children << doc
      @stack.push doc
    end
  end
end
