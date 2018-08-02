require "./tree.cr"

module Chalk
  module Trees
    class PrintVisitor < Visitor
      def initialize(@stream : IO)
        @indent = 0
      end

      def print_indent
        @indent.times do
          @stream << "  "
        end
      end

      def visit(id : TreeId)
        print_indent
        @stream << id.id << "\n"
      end

      def visit(lit : TreeLit)
        print_indent
        @stream << lit.lit << "\n"
      end

      def visit(op : TreeOp)
        print_indent
        @stream << "[op] "
        @stream << op.op << "\n"
        @indent += 1
      end

      def finish(op : TreeOp)
        @indent -= 1
      end

      def visit(function : TreeFunction)
        print_indent
        @stream << "[function] " << function.name << "( "
        function.params.each do |param|
          @stream << param << " "
        end
        @stream << ")" << "\n"
        @indent += 1
      end

      def finish(function : TreeFunction)
        @indent -= 1
      end

      macro forward(text, type)
      def visit(tree : {{type}})
        print_indent
        @stream << {{text}} << "\n"
        @indent += 1
      end

      def finish(tree : {{type}})
        @indent -= 1
      end
    end

      forward("[call]", TreeCall)
      forward("[block]", TreeBlock)
      forward("[var]", TreeVar)
      forward("[assign]", TreeAssign)
      forward("[if]", TreeIf)
      forward("[while]", TreeWhile)
      forward("[return]", TreeReturn)
    end

    class Tree
      def to_s(io)
        accept(PrintVisitor.new io)
      end
    end
  end
end
