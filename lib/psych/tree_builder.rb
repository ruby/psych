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

    %w{
      Document
      Sequence
      Mapping
    }.each do |node|
      class_eval %{
        def start_#{node.downcase}(*args)
          super
          n = Nodes::#{node}.new(*args)
          @stack.last.children << n
          @stack.push n
        end

        def end_#{node.downcase}(*args)
          super
          @stack.pop
        end
      }
    end

    def start_stream encoding
      super
      @stack.push Nodes::Stream.new(encoding)
    end

    def scalar(*args)
      super
      @stack.last.children << Nodes::Scalar.new(*args)
    end

    def alias(*args)
      super
      @stack.last.children << Nodes::Alias.new(*args)
    end
  end
end
