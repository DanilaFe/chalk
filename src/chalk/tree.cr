module Chalk
  class Visitor
    def visit(tree : Tree)
    end

    def finish(tree : Tree)
    end
  end

  class Transformer
    def transform(tree : Tree) : Tree
      return tree
    end
  end

  class Tree
    def accept(v : Visitor)
      v.visit(self)
      v.finish(self)
    end

    def apply(t : Transformer)
      return t.transform(self)
    end
  end

  class TreeId < Tree
    property id : String

    def initialize(@id : String)
    end
  end

  class TreeLit < Tree
    property lit : Int64

    def initialize(@lit : Int64)
    end
  end

  class TreeCall < Tree
    property name : String
    property params : Array(Tree)

    def initialize(@name : String, @params : Array(Tree))
    end

    def accept(v : Visitor)
      v.visit(self)
      @params.each &.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @params.map! do |param|
        param.apply(t)
      end
      return t.transform(self)
    end
  end

  class TreeOp < Tree
    property op : TokenType
    property left : Tree
    property right : Tree

    def initialize(@op : TokenType, @left : Tree, @right : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @left.accept(v)
      @right.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @left = @left.apply(t)
      @right = @right.apply(t)
      return t.transform(self)
    end
  end

  class TreeBlock < Tree
    property children : Array(Tree)

    def initialize(@children : Array(Tree))
    end

    def accept(v : Visitor)
      v.visit(self)
      @children.each &.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
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

    def initialize(@name : String, @params : Array(String), @block : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @block.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @block = @block.apply(t)
      return t.transform(self)
    end
  end

  class TreeVar < Tree
    property name : String
    property expr : Tree

    def initialize(@name : String, @expr : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @expr.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @expr = @expr.apply(t)
      return t.transform(self)
    end
  end

  class TreeAssign < Tree
    property name : String
    property expr : Tree

    def initialize(@name : String, @expr : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @expr.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @expr = @expr.apply(t)
      return t.transform(self)
    end
  end

  class TreeIf < Tree
    property condition : Tree
    property block : Tree
    property otherwise : Tree?

    def initialize(@condition : Tree, @block : Tree, @otherwise : Tree? = nil)
    end

    def accept(v : Visitor)
      v.visit(self)
      @condition.accept(v)
      @block.accept(v)
      @otherwise.try &.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @condition = @condition.apply(t)
      @block = @block.apply(t)
      @otherwise = @otherwise.try &.apply(t)
      return t.transform(self)
    end
  end

  class TreeWhile < Tree
    property condition : Tree
    property block : Tree

    def initialize(@condition : Tree, @block : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @condition.accept(v)
      @block.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @condition = @condition.apply(t)
      @block = @block.apply(t)
      return t.transform(self)
    end
  end

  class TreeReturn < Tree
    property rvalue : Tree

    def initialize(@rvalue : Tree)
    end

    def accept(v : Visitor)
      v.visit(self)
      @rvalue.accept(v)
      v.finish(self)
    end

    def apply(t : Transformer)
      @rvalue = @rvalue.apply(t)
      return t.transform(self)
    end
  end
end
