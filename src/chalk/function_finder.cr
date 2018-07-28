module Chalk
  class CallVisitor < Visitor
    property calls : Set(String)

    def initialize
      @calls = Set(String).new
    end

    def visit(t : TreeCall)
      @calls << t.name
    end
  end
end
