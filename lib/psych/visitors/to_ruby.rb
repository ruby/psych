require 'psych/scalar_scanner'

module Psych
  module Visitors
    ###
    # This class walks a YAML AST, converting each node to ruby
    class ToRuby < Psych::Visitors::Visitor
      def initialize
        super
        @st = {}
      end

      def visit_Psych_Nodes_Scalar o
        @st[o.anchor] = o.value if o.anchor

        return o.value if o.quoted

        case o.tag
        when '!str', 'tag:yaml.org,2002:str'
          o.value
        when "!ruby/object:Complex"
          Complex(o.value)
        when "!ruby/object:Rational"
          Rational(o.value)
        when "!ruby/regexp"
          o.value =~ /^\/(.*)\/([mix]*)$/
          source  = $1
          options = 0
          lang    = nil
          ($2 || '').split('').each do |option|
            case option
            when 'x' then options |= Regexp::EXTENDED
            when 'i' then options |= Regexp::IGNORECASE
            when 'm' then options |= Regexp::MULTILINE
            else lang = option
            end
          end
          Regexp.new(*[source, options, lang].compact)
        when "!ruby/range"
          args = o.value.split(/([.]{2,3})/, 2).map { |s|
            accept Nodes::Scalar.new(s)
          }
          args.push(args.delete_at(1) == '...')
          Range.new(*args)
        else
          token = ScalarScanner.new(o.value).tokenize

          case token.first
          when :DATE
            require 'date'
            Date.strptime token.last, '%Y-%m-%d'
          when :TIME
            lexeme = token.last

            date, time = *(lexeme.split(/[ tT]/, 2))
            (yy, m, dd) = date.split('-').map { |x| x.to_i }
            md = time.match(/(\d+:\d+:\d+)(\.\d*)?\s*(Z|[-+]\d+(:\d\d)?)?/)

            (hh, mm, ss) = md[1].split(':').map { |x| x.to_i }

            time = Time.utc(yy, m, dd, hh, mm, ss)

            tz = (!md[3] || md[3] == 'Z') ? 0 : Integer(md[3].split(':').first)
            Time.at((time - (tz * 3600)).to_i, md[2].sub(/^\./, '').to_i)
          else
            token.last
          end
        end
      end

      def visit_Psych_Nodes_Sequence o
        list = []
        @st[o.anchor] = list if o.anchor
        o.children.each { |c| list.push accept c }
        list
      end

      def visit_Psych_Nodes_Mapping o
        case o.tag
        when '!ruby/range'
          h = Hash[*o.children.map { |c| accept c }]
          Range.new(h['begin'], h['end'], h['excl'])

        when "!ruby/exception"
          h = Hash[*o.children.map { |c| accept c }]
          Exception.new h['message']

        when '!ruby/object:Complex'
          h = Hash[*o.children.map { |c| accept c }]
          Complex(h['real'], h['image'])

        when '!ruby/object:Rational'
          h = Hash[*o.children.map { |c| accept c }]
          Rational(h['numerator'], h['denominator'])

        else
          hash = {}
          @st[o.anchor] = hash if o.anchor
          o.children.map { |c| accept c }.each_slice(2) { |k,v|
            hash[k] = v
          }
          hash
        end
      end

      def visit_Psych_Nodes_Document o
        accept o.root
      end

      def visit_Psych_Nodes_Stream o
        o.children.map { |c| accept c }
      end

      def visit_Psych_Nodes_Alias o
        @st[o.anchor]
      end
    end
  end
end
