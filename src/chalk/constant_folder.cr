require "./tree.cr"

module Chalk
  class ConstantFolder < Transformer
    private def perform_op(op, left, right)
      case op
      when TokenType::OpAdd
        left + right
      when TokenType::OpSub
        left - right
      when TokenType::OpMul
        left*right
      when TokenType::OpDiv
        left/right
      when TokenType::OpAnd
        left & right
      when TokenType::OpOr
        left | right
      else TokenType::OpXor
      left ^ right
      end
    end

    def transform(tree : TreeOp)
      if tree.left.is_a?(TreeLit) && tree.right.is_a?(TreeLit)
        return TreeLit.new perform_op(tree.op,
          tree.left.as(TreeLit).lit,
          tree.right.as(TreeLit).lit)
      end
      return tree
    end
  end
end
