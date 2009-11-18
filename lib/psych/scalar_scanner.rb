require 'strscan'

module Psych
  ###
  # Scan scalars for built in types
  class ScalarScanner
    # Taken from http://yaml.org/type/timestamp.html
    TIME = /\d{4}-\d{1,2}-\d{1,2}([Tt]|\s+)\d{1,2}:\d\d:\d\d(\.\d*)?(\s*Z|[-+]\d{1,2}(:\d\d)?)?/

    def initialize string
      @string = string
    end

    def tokenize
      return [:NULL, nil] if @string.empty?

      case @string
      when /^[A-Za-z~]/
        case @string
        when /^(null|~)$/i
          [:NULL, nil]
        when /^(yes|true|on)$/i
          [:BOOLEAN, true]
        when /^(no|false|off)$/i
          [:BOOLEAN, false]
        else
          [:SCALAR, @string]
        end
      when TIME
        [:TIME, @string]
      when /^\d{4}-\d{1,2}-\d{1,2}$/
        [:DATE, @string]
      when /^\.inf$/i
        [:POSITIVE_INFINITY, 1 / 0.0]
      when /^-\.inf$/i
        [:NEGATIVE_INFINITY, -1 / 0.0]
      when /^\.nan$/i
        [:NAN, 0.0 / 0.0]
      when /^:.+/
        if @string =~ /^:(["'])(.*)\1/
          [:SYMBOL, $2.sub(/^:/, '').to_sym]
        else
          [:SYMBOL, @string.sub(/^:/, '').to_sym]
        end
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
        return [:INTEGER, Integer(@string.gsub(/[,_]/, ''))] rescue ArgumentError
        return [:FLOAT, Float(@string.gsub(/[,_]/, ''))] rescue ArgumentError

        [:SCALAR, @string]
      end
    end
  end
end
