module Psych
  module Visitable
    def accept target
      target.accept self
    end
  end
end
