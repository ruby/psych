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
        return result unless target.tag

        short_name = target.tag.sub(/^!/, '').split('/', 2).last
        if Psych.domain_types.key? short_name
          url, block = Psych.domain_types[short_name]
          return block.call "http://#{url}:#{short_name}", result
        end

        result
      end

      def visit_Psych_Nodes_Scalar o
        @st[o.anchor] = o.value if o.anchor

        return o.value if o.quoted
        return resolve_unknown(o) unless o.tag

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
          resolve_unknown o
        end
      end

      def visit_Psych_Nodes_Sequence o
        case o.tag
        when '!omap', 'tag:yaml.org,2002:omap'
          map = Psych::Omap.new
          @st[o.anchor] = map if o.anchor
          o.children.each { |a|
            map[accept(a.children.first)] = accept a.children.last
          }
          map
        else
          list = []
          @st[o.anchor] = list if o.anchor
          o.children.each { |c| list.push accept c }
          list
        end
      end

      def visit_Psych_Nodes_Mapping o
        case o.tag
        when '!str', 'tag:yaml.org,2002:str'
          members = Hash[*o.children.map { |c| accept c }]
          string = members.delete 'str'
          init_with(string, members.map { |k,v| [k.to_s.sub(/^@/, ''),v] })
        when /!ruby\/struct:?(.*)?$/
          klass   = resolve_class($1)

          if klass
            s = klass.allocate
            @st[o.anchor] = s if o.anchor

            members = {}
            struct_members = s.members.map { |x| x.to_sym }
            o.children.each_slice(2) do |k,v|
              member = accept(k)
              value  = accept(v)
              if struct_members.include?(member.to_sym)
                s.send("#{member}=", value)
              else
                members[member.to_s.sub(/^@/, '')] = value
              end
            end
            init_with(s, members)
          else
            members = o.children.map { |c| accept c }
            h = Hash[*members]
            Struct.new(*h.map { |k,v| k.to_sym }).new(*h.map { |k,v| v })
          end

        when '!ruby/range'
          h = Hash[*o.children.map { |c| accept c }]
          Range.new(h['begin'], h['end'], h['excl'])

        when /!ruby\/exception:?(.*)?$/
          h = Hash[*o.children.map { |c| accept c }]

          e = build_exception((resolve_class($1) || Exception),
                              h.delete('message'))
          init_with(e, h)
          e

        when '!set', 'tag:yaml.org,2002:set'
          set = Psych::Set.new
          @st[o.anchor] = set if o.anchor
          o.children.map { |c| accept c }.each_slice(2) do |k,v|
            set[k] = v
          end
          set

        when '!ruby/object:Complex'
          h = Hash[*o.children.map { |c| accept c }]
          Complex(h['real'], h['image'])

        when '!ruby/object:Rational'
          h = Hash[*o.children.map { |c| accept c }]
          Rational(h['numerator'], h['denominator'])

        when /!ruby\/object:?(.*)?$/
          name = $1 || 'Object'
          h = Hash[*o.children.map { |c| accept c }]
          s = name.split('::').inject(Object) { |k,sub|
            k.const_get sub
          }.allocate
          init_with(s, h)
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

      private
      def init_with o, h
        if o.respond_to?(:init_with)
          o.init_with h
        else
          h.each { |k,v| o.instance_variable_set(:"@#{k}", v) }
        end
        o
      end

      # Convert +klassname+ to a Class
      def resolve_class klassname
        return nil unless klassname and not klassname.empty?

        name    = klassname
        retried = false

        begin
          path2class(name)
        rescue ArgumentError => ex
          name    = "Struct::#{name}"
          unless retried
            retried = true
            retry
          end
          raise ex
        end
      end

      def resolve_unknown o
        type, lexeme = ScalarScanner.new(o.value).tokenize
        return lexeme unless :TIME == type

        date, time = *(lexeme.split(/[ tT]/, 2))
        (yy, m, dd) = date.split('-').map { |x| x.to_i }
        md = time.match(/(\d+:\d+:\d+)(\.\d*)?\s*(Z|[-+]\d+(:\d\d)?)?/)

        (hh, mm, ss) = md[1].split(':').map { |x| x.to_i }
        us = (md[2] ? Rational(md[2].sub(/^\./, '0.')) : 0) * 1000000

        time = Time.utc(yy, m, dd, hh, mm, ss, us)

        return time if 'Z' == md[3]

        tz = md[3] ? Integer(md[3].split(':').first) : 0
        Time.at((time - (tz * 3600)).to_i, us)
      end
    end
  end
end
