class Object
  def self.yaml_tag url
    Psych.add_tag(url, self)
  end

  def psych_to_yaml options = {}
    Psych.dump self, options
  end
  alias :to_yaml :psych_to_yaml
end

module Kernel
  def y *objects
    puts Psych.dump_stream(*objects)
  end
end
