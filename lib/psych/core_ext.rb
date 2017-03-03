# frozen_string_literal: false
class Object
  def self.yaml_tag url
    Psych.add_tag(url, self)
  end

  ###
  # call-seq: to_yaml(options = {})
  #
  # Convert an object to YAML.  See Psych.dump for more information on the
  # available +options+.
  def to_yaml options = {}
    Psych.dump self, options
  end
end

class Module
  def psych_yaml_as url
    return if caller[0].end_with?('rubytypes.rb')
    if $VERBOSE
      warn "#{caller[0]}: yaml_as is deprecated, please use yaml_tag"
    end
    Psych.add_tag(url, self)
  end

  remove_method :yaml_as rescue nil
  alias :yaml_as :psych_yaml_as
end

if defined?(::IRB)
  require 'psych/y'
end
