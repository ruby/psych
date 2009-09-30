require 'strscan'

module Psych
  ###
  # Scan scalars for built in types
  class ScalarScanner
    def initialize string
      @string = string
    end

    def tokenize
      return [:NULL, nil] if @string.empty?

      case @string
      when /^\.inf$/i
        [:POSITIVE_INFINITY, 1 / 0.0]
      when /^-\.inf$/i
        [:NEGATIVE_INFINITY, -1 / 0.0]
      when /^\.nan$/i
        [:NAN, 0.0 / 0.0]
      when /^(null|~)$/i
        [:NULL, nil]
      when /^:/i
        [:SYMBOL, @string.sub(/^:/, '').to_sym]
      when /^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$/
        i = 0
        @string.split(':').each_with_index do |n,e|
          i += (n.to_i * 60 ** (e - 2).abs)
        end

        [:INTEGER, i]
      when /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$/
        i = 0
        @string.split(':').each_with_index do |n,e|
          i += (n.to_f * 60 ** (e - 2).abs)
        end

        [:FLOAT, i]
      else
        return [:FLOAT, Float(@string.gsub(/[,_]/, ''))] rescue ArgumentError
        return [:INTEGER, Integer(@string.gsub(/[,_]/, ''))] rescue ArgumentError

        [:SCALAR, @string]
      end
    end
  end
end
