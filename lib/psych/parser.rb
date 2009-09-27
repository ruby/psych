module Psych
  ###
  # YAML parser class.
  #
  # Example:
  #
  #   parser = Psych::Parser.new
  #   parser.parse(some_yaml)
  class Parser
    attr_accessor :handler

    def initialize handler = Handler.new
      @handler = handler
    end

    def parse string
      parse_string string
    end
  end
end
