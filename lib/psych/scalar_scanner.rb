require 'strscan'
require 'time'

module Psych
  ###
  # Scan scalars for built in types
  class ScalarScanner
    # Taken from http://yaml.org/type/timestamp.html
    TIME = /^\d{4}-\d{1,2}-\d{1,2}([Tt]|\s+)\d{1,2}:\d\d:\d\d(\.\d*)?(\s*Z|[-+]\d{1,2}(:\d\d)?)?/

    # Taken from http://yaml.org/type/float.html
    FLOAT = /^(?:[-+]?([0-9][0-9_,]*)?\.[0-9.]*([eE][-+][0-9]+)?(?# base 10)
              |[-+]?[0-9][0-9_,]*(:[0-5]?[0-9])+\.[0-9_]*(?# base 60)
              |[-+]?\.(inf|Inf|INF)(?# infinity)
              |\.(nan|NaN|NAN)(?# not a number))$/x

    # Create a new scanner
    def initialize
      @string_cache = {}
    end

    # Tokenize +string+ returning the ruby object
    def tokenize string
      return nil if string.empty?
      return string if @string_cache.key?(string)

      case string
      when /^[A-Za-z~]/
        if string.length > 5
          @string_cache[string] = true
          return string
        end

        case string
        when /^[^ytonf~]/i
          @string_cache[string] = true
          string
        when '~', /^null$/i
          nil
        when /^(yes|true|on)$/i
          true
        when /^(no|false|off)$/i
          false
        else
          @string_cache[string] = true
          string
        end
      when TIME
        parse_time string
      when /^\d{4}-(?:1[012]|0\d|\d)-(?:[12]\d|3[01]|0\d|\d)$/
        require 'date'
        begin
          Date.strptime(string, '%Y-%m-%d')
        rescue ArgumentError
          string
        end
      when /^\.inf$/i
        1 / 0.0
      when /^-\.inf$/i
        -1 / 0.0
      when /^\.nan$/i
        0.0 / 0.0
      when /^:./
        if string =~ /^:(["'])(.*)\1/
          $2.sub(/^:/, '').to_sym
        else
          string.sub(/^:/, '').to_sym
        end
      when /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+$/
        i = 0
        string.split(':').each_with_index do |n,e|
          i += (n.to_i * 60 ** (e - 2).abs)
        end
        i
      when /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$/
        i = 0
        string.split(':').each_with_index do |n,e|
          i += (n.to_f * 60 ** (e - 2).abs)
        end
        i
      when FLOAT
        begin
          return Float(string.gsub(/[,_]/, ''))
        rescue ArgumentError
        end

        @string_cache[string] = true
        string
      else
        if string.count('.') < 2
          begin
            return Integer(string.gsub(/[,_]/, ''))
          rescue ArgumentError
          end
        end

        @string_cache[string] = true
        string
      end
    end

    ###
    # Parse and return a Time from +string+
    def parse_time string
      Time.rfc2822(string) rescue Time.parse(string)
    end
  end
end
