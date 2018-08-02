module Chalk
  module Trees
    # Visitor that finds all function calls in a function.
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
end
