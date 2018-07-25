require "./builder.cr"

module Chalk
    class Parser
        include Builder

        private def create_type
            either(type(TokenType::KwU0), type(TokenType::KwU8), type(TokenType::KwU12))
        end

        private def create_lit
            dec_parser = type(TokenType::LitDec).transform &.string.to_i64
            hex_parser = type(TokenType::LitHex).transform &.string.lchop("0x").to_i64(16)
            bin_parser = type(TokenType::LitBin).transform &.string.lchop("0b").to_i64(2)
            lit_parser = either(dec_parser, hex_parser, bin_parser).transform { |it| TreeLit.new(it).as(Tree) }
            return lit_parser
        end

        private def create_op_expr(atom, op)
            pl = PlaceholderParser(Tree).new
            recurse = atom.then(op).then(pl).transform do |arr|
                arr = arr.flatten
                TreeOp.new(
                    arr[1].as(Token).type,
                    arr[0].as(Tree),
                    arr[2].as(Tree)).as(Tree)
            end
            pl.parser = either(recurse, atom)
            return pl
        end

        private def create_op_exprs(atom, ops)
            ops.reduce(atom) do |previous, current|
                create_op_expr(previous, current)
            end
        end

        private def create_call(expr)
            call = type(TokenType::Id).then(char '(').then(delimited(expr, char ',')).then(char ')').transform do |arr|
                arr = arr.flatten
                name = arr[0].as(Token).string
                params = arr[2..arr.size - 2].map &.as(Tree)
                TreeCall.new(name, params).as(Tree)
            end
            return call
        end

        private def create_expr
            expr_place = PlaceholderParser(Tree).new
            literal = create_lit
            id = type(TokenType::Id).transform { |it| TreeId.new(it.string).as(Tree) }
            call = create_call(expr_place)
            atom = either(literal, call, id)

            ops = [ either(type(TokenType::OpMul), type(TokenType::OpDiv)),
                    either(type(TokenType::OpAdd), type(TokenType::OpSub)),
                    type(TokenType::OpXor),
                    type(TokenType::OpAnd),
                    type(TokenType::OpOr) ]
            expr = create_op_exprs(atom, ops)
            expr_place.parser = expr

            return expr
        end

        private def create_var(expr)
            var = type(TokenType::KwVar).then(type(TokenType::Id)).then(char '=').then(expr).then(char ';').transform do |arr|
                arr = arr.flatten
                name = arr[1].as(Token).string
                exp = arr[arr.size - 2].as(Tree)
                TreeVar.new(name, exp).as(Tree)
            end
            return var
        end

        private def create_assign(expr)
            assign = type(TokenType::Id).then(char '=').then(expr).then(char ';').transform do |arr|
                arr = arr.flatten
                name = arr[0].as(Token).string
                exp = arr[arr.size - 2].as(Tree)
                TreeAssign.new(name, exp).as(Tree)
            end
            return assign
        end

        private def create_basic(expr)
            basic = expr.then(char ';').transform do |arr|
                arr.flatten[0].as(Tree)
            end
            return basic
        end

        private def create_if(expr, block)
            iff = type(TokenType::KwIf).then(char '(').then(expr).then(char ')').then(block)
                .then(optional(type(TokenType::KwElse).then(block)))
                .transform do |arr|
                arr = arr.flatten
                cond = arr[2].as(Tree)
                code = arr[4].as(Tree)
                otherwise = arr.size == 7 ? arr[6].as(Tree) : nil
                TreeIf.new(cond, code, otherwise).as(Tree)
            end
            return iff
        end

        private def create_while(expr, block)
            whilee = type(TokenType::KwWhile).then(char '(').then(expr).then(char ')').then(block).transform do |arr|
                arr = arr.flatten
                cond = arr[2].as(Tree)
                code = arr[4].as(Tree)
                TreeWhile.new(cond, code).as(Tree)
            end
            return whilee
        end

        private def create_return(expr)
            returnn = type(TokenType::KwReturn).then(expr).then(char ';').transform do |arr|
                arr = arr.flatten
                value = arr[1].as(Tree)
                TreeReturn.new(value).as(Tree)
            end
            return returnn
        end

        private def create_block(statement)
            block = char('{').then(many(statement)).then(char '}').transform do |arr|
                arr = arr.flatten
                params = arr[1..arr.size - 2].map &.as(Tree)
                TreeBlock.new(params).as(Tree)
            end
            return block
        end

        private def create_statement_block
            statement_place = PlaceholderParser(Tree).new
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

        private def create_func(block, type)
            func = type(TokenType::KwFun).then(type(TokenType::Id))
                .then(char '(').then(delimited(type(TokenType::Id), char ',')).then(char ')')
                .then(char ':').then(type)
                .then(block).transform do |arr|
                arr = arr.flatten
                name = arr[1].as(Token).string
                params = arr[3..arr.size - 5].map &.as(Token).string
                code = arr[arr.size - 1].as(Tree)
                type = arr[arr.size - 2].as(Token).type
                TreeFunction.new(name, params, code).as(Tree)
            end
            return func
        end

        def initialize
            _, block = create_statement_block
            @parser = many(create_func(block, create_type)).as(BasicParser(Array(Tree)))
        end

        def parse?(tokens)
            return @parser.parse?(tokens, 0).try &.[0]
        end
    end
end
