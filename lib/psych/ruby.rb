class Object
  include Psych::Visitable

  def to_yaml options = {}
    Psych::YASTBuilder.new(options).accept self
  end
end
