require "./parser_builder.cr"

module Chalk
  module ParserCombinators
    # Parser created out of the various parser combinators.
    class Parser
      include ParserBuilder

      # Creates a parser for a type.
      private def create_type
        either(type(Compiler::TokenType::KwU0),
               type(Compiler::TokenType::KwU4),
               type(Compiler::TokenType::KwU8),
               type(Compiler::TokenType::KwU12))
      end

      # Creates a parser for an integer literal.
      private def create_lit
        dec_parser = type(Compiler::TokenType::LitDec).transform &.string.to_i64
        hex_parser = type(Compiler::TokenType::LitHex).transform &.string.lchop("0x").to_i64(16)
        bin_parser = type(Compiler::TokenType::LitBin).transform &.string.lchop("0b").to_i64(2)
        lit_parser = either(dec_parser, hex_parser, bin_parser).transform { |it| Trees::TreeLit.new(it).as(Trees::Tree) }
        return lit_parser
      end

      # Creates a parser for an operation with a given *atom* parser
      # and *op* parser.
      private def create_op_expr(atom, op)
        pl = PlaceholderParser(Trees::Tree).new
        recurse = atom.then(op).then(pl).transform do |arr|
          arr = arr.flatten
          Trees::TreeOp.new(
            arr[1].as(Compiler::Token).type,
            arr[0].as(Trees::Tree),
            arr[2].as(Trees::Tree)).as(Trees::Tree)
        end
        pl.parser = either(recurse, atom)
        return pl
      end

      # Creates a parser to parse layers of *ops* with multiple
      # levels of precedence, specified by their order. The *atom*
      # is the most basic expression.
      private def create_op_exprs(atom, ops)
        ops.reduce(atom) do |previous, current|
          create_op_expr(previous, current)
        end
      end

      # Creates a parser for a call, with the given expression parser.
      private def create_call(expr)
        call = type(Compiler::TokenType::Id).then(char '(').then(delimited(expr, char ',')).then(char ')').transform do |arr|
          arr = arr.flatten
          name = arr[0].as(Compiler::Token).string
          params = arr[2..arr.size - 2].map &.as(Trees::Tree)
          Trees::TreeCall.new(name, params).as(Trees::Tree)
        end
        return call
      end

      # Creates a parser for an expression.
      private def create_expr
        expr_place = PlaceholderParser(Trees::Tree).new
        literal = create_lit
        id = type(Compiler::TokenType::Id).transform { |it| Trees::TreeId.new(it.string).as(Trees::Tree) }
        call = create_call(expr_place)
        atom = either(literal, call, id)

        ops = [either(type(Compiler::TokenType::OpMul), type(Compiler::TokenType::OpDiv)),
               either(type(Compiler::TokenType::OpAdd), type(Compiler::TokenType::OpSub)),
               type(Compiler::TokenType::OpXor),
               type(Compiler::TokenType::OpAnd),
               type(Compiler::TokenType::OpOr)]
        expr = create_op_exprs(atom, ops)
        expr_place.parser = expr

        return expr
      end

      # Creates a parser for a var statement.
      private def create_var(expr)
        var = type(Compiler::TokenType::KwVar).then(type(Compiler::TokenType::Id)).then(char '=').then(expr).then(char ';').transform do |arr|
          arr = arr.flatten
          name = arr[1].as(Compiler::Token).string
          exp = arr[arr.size - 2].as(Trees::Tree)
          Trees::TreeVar.new(name, exp).as(Trees::Tree)
        end
        return var
      end

      # Creates a parser for an assignment statement.
      private def create_assign(expr)
        assign = type(Compiler::TokenType::Id).then(char '=').then(expr).then(char ';').transform do |arr|
          arr = arr.flatten
          name = arr[0].as(Compiler::Token).string
          exp = arr[arr.size - 2].as(Trees::Tree)
          Trees::TreeAssign.new(name, exp).as(Trees::Tree)
        end
        return assign
      end

      # Creates a parser for a basic statement.
      private def create_basic(expr)
        basic = expr.then(char ';').transform do |arr|
          arr.flatten[0].as(Trees::Tree)
        end
        return basic
      end

      # Creates a parser for an if statement.
      private def create_if(expr, block)
        iff = type(Compiler::TokenType::KwIf).then(char '(').then(expr).then(char ')').then(block)
          .then(optional(type(Compiler::TokenType::KwElse).then(block)))
          .transform do |arr|
            arr = arr.flatten
            cond = arr[2].as(Trees::Tree)
            code = arr[4].as(Trees::Tree)
            otherwise = arr.size == 7 ? arr[6].as(Trees::Tree) : nil
            Trees::TreeIf.new(cond, code, otherwise).as(Trees::Tree)
          end
        return iff
      end

      # Creates a parser for a while loop.
      private def create_while(expr, block)
        whilee = type(Compiler::TokenType::KwWhile).then(char '(').then(expr).then(char ')').then(block).transform do |arr|
          arr = arr.flatten
          cond = arr[2].as(Trees::Tree)
          code = arr[4].as(Trees::Tree)
          Trees::TreeWhile.new(cond, code).as(Trees::Tree)
        end
        return whilee
      end

      # Creates a parser for a return.
      private def create_return(expr)
        returnn = type(Compiler::TokenType::KwReturn).then(expr).then(char ';').transform do |arr|
          arr = arr.flatten
          value = arr[1].as(Trees::Tree)
          Trees::TreeReturn.new(value).as(Trees::Tree)
        end
        return returnn
      end

      # Creates a parser for a block of statements.
      private def create_block(statement)
        block = char('{').then(many(statement)).then(char '}').transform do |arr|
          arr = arr.flatten
          params = arr[1..arr.size - 2].map &.as(Trees::Tree)
          Trees::TreeBlock.new(params).as(Trees::Tree)
        end
        return block
      end

      # Creates a statement and block parser, returning both.
      private def create_statement_block
        statement_place = PlaceholderParser(Trees::Tree).new
        expr = create_expr
        block = create_block(statement_place)
        iff = create_if(expr, block)
        whilee = create_while(expr, block)
        returnn = create_return(expr)
        var = create_var(expr)
        assign = create_assign(expr)
        basic = create_basic(expr)
        statement = either(basic, var, assign, block, iff, whilee, returnn)
        statement_place.parser = statement
        return {statement, block}
      end

      # Creates a parser for a function declaration.
      private def create_func(block, type)
        func = type(Compiler::TokenType::KwFun).then(type(Compiler::TokenType::Id))
          .then(char '(').then(delimited(type(Compiler::TokenType::Id), char ',')).then(char ')')
          .then(char ':').then(type)
          .then(block).transform do |arr|
            arr = arr.flatten
            name = arr[1].as(Compiler::Token).string
            params = arr[3..arr.size - 5].map &.as(Compiler::Token).string
            code = arr[arr.size - 1].as(Trees::Tree)
            type = arr[arr.size - 2].as(Compiler::Token).type
            table = {
                Compiler::TokenType::KwU0 => Compiler::Type::U0,
                Compiler::TokenType::KwU4 => Compiler::Type::U4,
                Compiler::TokenType::KwU8 => Compiler::Type::U8,
                Compiler::TokenType::KwU12 => Compiler::Type::U12
            }
            Trees::TreeFunction.new(name, params, table[type], code)
          end
        return func
      end

      def initialize
        _, block = create_statement_block
        @parser = many(create_func(block, create_type)).as(BasicParser(Array(Trees::TreeFunction)))
      end

      # Parses the given tokens into a tree.
      def parse?(tokens)
        return @parser.parse?(tokens, 0).try &.[0]
      end
    end
  end
end
