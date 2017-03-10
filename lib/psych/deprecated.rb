# frozen_string_literal: false
require 'date'

module Psych
  DEPRECATED = __FILE__ # :nodoc:

  module DeprecatedMethods # :nodoc:
    attr_accessor :taguri
    attr_accessor :to_yaml_style
  end
end

class Object
  undef :to_yaml_properties rescue nil
  def to_yaml_properties # :nodoc:
    instance_variables
  end
end
