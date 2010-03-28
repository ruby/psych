#require 'date'
#YAML = Psych
#
#[
#  Object, String, Class, Hash, Array, NilClass, Float, FalseClass, TrueClass,
#  Range, Complex, Rational, Date, Time, Regexp, Exception, Struct
#].each do |klass|
#  klass.send(:remove_method, :to_yaml) rescue NameError
#end

class Object
  def self.yaml_tag url
    Psych.add_tag(url, self)
  end

  def psych_to_yaml options = {}
    Psych.dump self, options
  end
  #alias :to_yaml :psych_to_yaml
end
