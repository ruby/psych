module Psych
  class Parser
    ###
    # Default event handlers used in conjunction with Psych::Parser
    class Handler
      ###
      # Called with +encoding+ when the YAML stream starts.
      def start_stream encoding
      end

      ###
      # Called when the document starts with the declared +version+ and
      # +tag_directives+
      def start_document version = [], tag_directives = []
      end

      ###
      # Called when the YAML stream ends
      def end_stream
      end
    end
  end
end
