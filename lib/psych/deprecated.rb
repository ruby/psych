# frozen_string_literal: false
require 'date'

module Psych
  DEPRECATED = __FILE__ # :nodoc:

  module DeprecatedMethods # :nodoc:
    attr_accessor :taguri
    attr_accessor :to_yaml_style
  end

  def self.detect_implicit thing
    warn "#{caller[0]}: detect_implicit is deprecated" if $VERBOSE
    return '' unless String === thing
    return 'null' if '' == thing
    ss = ScalarScanner.new(ClassLoader.new)
    ss.tokenize(thing).class.name.downcase
  end

  def self.add_ruby_type type_tag, &block
    warn "#{caller[0]}: add_ruby_type is deprecated, use add_domain_type" if $VERBOSE
    domain = 'ruby.yaml.org,2002'
    key = ['tag', domain, type_tag].join ':'
    @domain_types[key] = [key, block]
  end

  def self.add_private_type type_tag, &block
    warn "#{caller[0]}: add_private_type is deprecated, use add_domain_type" if $VERBOSE
    domain = 'x-private'
    key = [domain, type_tag].join ':'
    @domain_types[key] = [key, block]
  end

  def self.tagurize thing
    warn "#{caller[0]}: add_private_type is deprecated, use add_domain_type" if $VERBOSE
    return thing unless String === thing
    "tag:yaml.org,2002:#{thing}"
  end

  def self.read_type_class type, reference
    warn "#{caller[0]}: read_type_class is deprecated" if $VERBOSE
    _, _, type, name = type.split ':', 4

    reference = name.split('::').inject(reference) do |k,n|
      k.const_get(n.to_sym)
    end if name
    [type, reference]
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
