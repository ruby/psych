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

      def accept target
        result = super
        return result if Psych.domain_types.empty?

        if target.respond_to?(:tag) && target.tag
          short_name = target.tag.sub(/^!/, '').split('/').last
          if Psych.domain_types.key? short_name
            url, block = Psych.domain_types[short_name]
            block.call "http://#{url}:#{short_name}", result
          end
        end
        result
      end

      def visit_Psych_Nodes_Scalar o
        @st[o.anchor] = o.value if o.anchor

        return o.value if o.quoted

        case o.tag
        when '!binary', 'tag:yaml.org,2002:binary'
          o.value.unpack('m').first
        when '!str', 'tag:yaml.org,2002:str'
          o.value
        when "!ruby/object:Complex"
          Complex(o.value)
        when "!ruby/object:Rational"
          Rational(o.value)
        when "tag:yaml.org,2002:float", "!float"
          Float(ScalarScanner.new(o.value).tokenize.last)
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

            us = md[2] ? md[2].sub(/^\./, '').to_i : 0

            tz = (!md[3] || md[3] == 'Z') ? 0 : Integer(md[3].split(':').first)
            Time.at((time - (tz * 3600)).to_i, us)
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
        when /!ruby\/struct:?(.*)?$/
          klassname = $1
          h = Hash[*o.children.map { |c| accept c }].to_a

          if klassname && klassname.length > 1
            name    = klassname
            s       = nil
            retried = false

            begin
              s = name.split('::').inject(Object) { |k,sub|
                k.const_get sub
              }.allocate
            rescue NameError => ex
              name    = "Struct::#{name}"
              unless retried
                retried = true
                retry
              end
              raise ex
            end
            h.each { |k,v| s.send("#{k}=", v) }
            s
          else
            Struct.new(*h.map { |k,v| k.to_sym }).new(*h.map { |k,v| v })
          end

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

        when /!ruby\/object:?(.*)?$/
          name = $1.nil? ? 'Object' : $1
          h = Hash[*o.children.map { |c| accept c }]
          s = name.split('::').inject(Object) { |k,sub|
            k.const_get sub
          }.allocate
          h.each { |k,v| s.instance_variable_set(:"@#{k}", v) }
          s

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
