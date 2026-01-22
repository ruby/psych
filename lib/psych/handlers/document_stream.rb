# frozen_string_literal: true
require_relative '../tree_builder'

module Psych
  module Handlers
    class DocumentStream < Psych::TreeBuilder # :nodoc:
      def initialize &block
        super
        @block = block
      end

      def start_document version, tag_directives, implicit
        n = Nodes::Document.new version, tag_directives, implicit
        push n
      end

      def end_document implicit_end = !streaming?
        @last.implicit_end = implicit_end
        @block.call pop
      end

      def end_mapping
        mapping = pop
        keys = {}
        mapping.children.each_slice(2) do |(key_scalar, _)|
          next if key_scalar.is_a?(Psych::Nodes::Sequence) or key_scalar.is_a?(Psych::Nodes::Alias) or key_scalar.is_a?(Psych::Nodes::Mapping)
          key = key_scalar.value
          raise Psych::Exception, "Duplicate key #{key} exists on this level" if keys.key? key
          keys[key] = nil
        end
        mapping
      end
    end
  end
end
