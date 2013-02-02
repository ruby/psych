require 'psych/omap'
require 'psych/set'

module Psych
  class ClassLoader # :nodoc:
    BIG_DECIMAL = 'BigDecimal'
    COMPLEX     = 'Complex'
    DATE        = 'Date'
    DATE_TIME   = 'DateTime'
    EXCEPTION   = 'Exception'
    OBJECT      = 'Object'
    PSYCH_OMAP  = 'Psych::Omap'
    PSYCH_SET   = 'Psych::Set'
    RANGE       = 'Range'
    RATIONAL    = 'Rational'
    REGEXP      = 'Regexp'
    STRUCT      = 'Struct'
    SYMBOL      = 'Symbol'

    def initialize
      @cache = CACHE.dup
    end

    def load klassname
      return nil if !klassname || klassname.empty?

      find klassname
    end

    private

    def find klassname
      @cache[klassname] ||= resolve(klassname)
    end

    def resolve klassname
      name    = klassname
      retried = false

      begin
        path2class(name)
      rescue ArgumentError, NameError => ex
        unless retried
          name    = "Struct::#{name}"
          retried = ex
          retry
        end
        raise retried
      end
    end

    constants.each do |const|
      konst = const_get const
      define_method(const.to_s.downcase) do
        load konst
      end
    end

    CACHE = Hash[constants.map { |const|
      val = const_get const
      begin
        [val, ::Object.const_get(val)]
      rescue
        nil
      end
    }.compact]

    class Restricted < ClassLoader
      def initialize whitelist
        @whitelist = whitelist
        super()
      end

      private

      def find klassname
        if @whitelist.include? klassname
          super
        else
          raise DisallowedClass, klassname
        end
      end
    end
  end
end
