# frozen_string_literal: false
require 'date'

module Psych
  DEPRECATED = __FILE__ # :nodoc:

  module DeprecatedMethods # :nodoc:
    attr_accessor :taguri
    attr_accessor :to_yaml_style
  end

  def self.tagurize thing
    warn "#{caller[0]}: add_private_type is deprecated, use add_domain_type" if $VERBOSE
    return thing unless String === thing
    "tag:yaml.org,2002:#{thing}"
  end

  def self.object_maker klass, hash
    warn "#{caller[0]}: object_maker is deprecated" if $VERBOSE
    klass.allocate.tap do |obj|
      hash.each { |k,v| obj.instance_variable_set(:"@#{k}", v) }
    end
  end
end

class Object
  undef :to_yaml_properties rescue nil
  def to_yaml_properties # :nodoc:
    instance_variables
  end
end
