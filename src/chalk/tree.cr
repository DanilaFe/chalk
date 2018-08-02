module Chalk
  module Trees
    class Visitor
      def visit(tree)
      end

      def finish(tree)
      end
    end

    class Transformer
      def transform(tree)
        return tree
      end
    end

    class Tree
      def accept(v)
        v.visit(self)
        v.finish(self)
      end

      def apply(t)
        return t.transform(self)
      end
    end

    class TreeId < Tree
      property id : String

      def initialize(@id)
      end
    end

    class TreeLit < Tree
      property lit : Int64

      def initialize(@lit)
      end
    end

    class TreeCall < Tree
      property name : String
      property params : Array(Tree)

      def initialize(@name, @params)
      end

      def accept(v)
        v.visit(self)
        @params.each &.accept(v)
        v.finish(self)
      end

      def apply(t)
        @params.map! do |param|
          param.apply(t)
        end
        return t.transform(self)
      end
    end

    class TreeOp < Tree
      property op : Compiler::TokenType
      property left : Tree
      property right : Tree

      def initialize(@op, @left, @right)
      end

      def accept(v)
        v.visit(self)
        @left.accept(v)
        @right.accept(v)
        v.finish(self)
      end

      def apply(t)
        @left = @left.apply(t)
        @right = @right.apply(t)
        return t.transform(self)
      end
    end

    class TreeBlock < Tree
      property children : Array(Tree)

      def initialize(@children)
      end

      def accept(v)
        v.visit(self)
        @children.each &.accept(v)
        v.finish(self)
      end

      def apply(t)
        @children.map! do |child|
          child.apply(t)
        end
        return t.transform(self)
      end
    end

    class TreeFunction < Tree
      property name : String
      property params : Array(String)
      property block : Tree

      def initialize(@name, @params, @block)
      end

      def param_count
        return @params.size
      end

      def accept(v)
        v.visit(self)
        @block.accept(v)
        v.finish(self)
      end

      def apply(t)
        @block = @block.apply(t)
        return t.transform(self)
      end
    end

    class TreeVar < Tree
      property name : String
      property expr : Tree

      def initialize(@name, @expr)
      end

      def accept(v)
        v.visit(self)
        @expr.accept(v)
        v.finish(self)
      end

      def apply(t)
        @expr = @expr.apply(t)
        return t.transform(self)
      end
    end

    class TreeAssign < Tree
      property name : String
      property expr : Tree

      def initialize(@name, @expr)
      end

      def accept(v)
        v.visit(self)
        @expr.accept(v)
        v.finish(self)
      end

      def apply(t)
        @expr = @expr.apply(t)
        return t.transform(self)
      end
    end

    class TreeIf < Tree
      property condition : Tree
      property block : Tree
      property otherwise : Tree?

      def initialize(@condition, @block, @otherwise = nil)
      end

      def accept(v)
        v.visit(self)
        @condition.accept(v)
        @block.accept(v)
        @otherwise.try &.accept(v)
        v.finish(self)
      end

      def apply(t)
        @condition = @condition.apply(t)
        @block = @block.apply(t)
        @otherwise = @otherwise.try &.apply(t)
        return t.transform(self)
      end
    end

    class TreeWhile < Tree
      property condition : Tree
      property block : Tree

      def initialize(@condition, @block)
      end

      def accept(v)
        v.visit(self)
        @condition.accept(v)
        @block.accept(v)
        v.finish(self)
      end

      def apply(t)
        @condition = @condition.apply(t)
        @block = @block.apply(t)
        return t.transform(self)
      end
    end

    class TreeReturn < Tree
      property rvalue : Tree

      def initialize(@rvalue)
      end

      def accept(v)
        v.visit(self)
        @rvalue.accept(v)
        v.finish(self)
      end

      def apply(t)
        @rvalue = @rvalue.apply(t)
        return t.transform(self)
      end
    end
  end
end
