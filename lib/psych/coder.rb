module Psych
  class Coder < ::Hash
    def initialize map, h = nil
      super()
      merge!(h) if h
      @map = map
    end

    def tag= tag
      @map.tag = tag
    end

    def tag
      @map.tag
    end

    def style= style
      @map.style = style
    end

    def style
      @map.style
    end

    def implicit= implicity
      @map.implicit = implicity
    end

    def implicit
      @map.implicit
    end
  end
end
