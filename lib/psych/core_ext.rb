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
  def yaml_as url
    return if caller[0].end_with?('rubytypes.rb')
    if $VERBOSE
      warn "#{caller[0]}: yaml_as is deprecated, please use yaml_tag"
    end
    Psych.add_tag(url, self)
  end
end

if defined?(::IRB)
  require 'psych/y'
end
