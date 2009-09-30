[Object, String].each do |klass|
  klass.send(:remove_method, :to_yaml)
end

class Object
  include Psych::Visitable

  def to_yaml options = {}
    visitor = Psych::Visitors::YASTBuilder.new options
    visitor.accept self
    visitor.tree.to_yaml
  end
end
