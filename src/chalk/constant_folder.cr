require "./tree.cr"

module Chalk
  module Trees
    # `Trees::Transformer` that turns operations on
    # Constants into constants.
    class ConstantFolder < Transformer
      private def perform_op(op, left, right)
        case op
        when Compiler::TokenType::OpAdd
          left + right
        when Compiler::TokenType::OpSub
          left - right
        when Compiler::TokenType::OpMul
          left*right
        when Compiler::TokenType::OpDiv
          left/right
        when Compiler::TokenType::OpAnd
          left & right
        when Compiler::TokenType::OpOr
          left | right
        else Compiler::TokenType::OpXor
        left ^ right
        end
      end

      def transform(tree : Trees::TreeOp)
        if tree.left.is_a?(Trees::TreeLit) && tree.right.is_a?(Trees::TreeLit)
          return Trees::TreeLit.new perform_op(tree.op,
            tree.left.as(Trees::TreeLit).lit,
            tree.right.as(Trees::TreeLit).lit)
        end
        return tree
      end
    end
  end
end
