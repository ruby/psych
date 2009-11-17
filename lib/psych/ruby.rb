require 'complex'
require 'rational'
require 'date'

YAML = Psych

[
  Object, String, Class, Hash, Array, NilClass, Float, FalseClass, TrueClass,
  Range, Complex, Rational, Date, Time, Regexp, Exception, Struct
].each do |klass|
  klass.send(:remove_method, :to_yaml) rescue NameError
end

class Object
  include Psych::Visitable

  def to_yaml options = {}
    Psych.dump self, options
  end
end
