module Psych
  ###
  # Default event handlers used in conjunction with Psych::Parser
  class Handler
    ###
    # Called with +encoding+ when the YAML stream starts.
    def start_stream encoding
    end

    ###
    # Called when the document starts with the declared +version+,
    # +tag_directives+, if the document is +implicit+
    def start_document version, tag_directives, implicit
    end

    ###
    # Called with the document ends.
    def end_document implicit = true
    end

    ###
    # Called when an alias is found to +anchor+
    def alias anchor
    end

    ###
    # Called when a scalar +value+ is found.  The scalar may have an
    # +anchor+, a +tag+, be implicitly +plain+ or implicitly +quoted+
    def scalar value, anchor, tag, plain, quoted, style
    end

    ###
    # Called when a sequence is started.
    def start_sequence anchor, tag, implicit, style
    end

    ###
    # Called when a sequence ends.
    def end_sequence
    end

    ###
    # Called when a map starts
    def start_mapping anchor, tag, implicit, style
    end

    ###
    # Called when a map ends
    def end_mapping
    end

    ###
    # Called when an empty event happens. (Which, as far as I can tell, is
    # never).
    def empty
    end

    ###
    # Called when the YAML stream ends
    def end_stream
    end
  end
end
