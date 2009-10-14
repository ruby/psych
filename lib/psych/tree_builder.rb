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
      @last  = nil
    end

    def root
      @stack.first
    end

    %w{
      Sequence
      Mapping
    }.each do |node|
      class_eval %{
        def start_#{node.downcase}(*args)
          n = Nodes::#{node}.new(*args)
          @last.children << n
          push n
        end

        def end_#{node.downcase}
          pop
        end
      }
    end

    def start_document(*args)
      n = Nodes::Document.new(*args)
      @last.children << n
      push n
    end

    def end_document implicit_end
      @last.implicit_end = implicit_end
      pop
    end

    def start_stream encoding
      push Nodes::Stream.new(encoding)
    end

    def scalar(*args)
      @last.children << Nodes::Scalar.new(*args)
    end

    def alias(*args)
      @last.children << Nodes::Alias.new(*args)
    end

    private
    def push value
      @stack.push value
      @last = value
    end

    def pop
      @stack.pop
      @last = @stack.last
    end
  end
end
