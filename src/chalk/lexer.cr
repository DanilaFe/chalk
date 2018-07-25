require "lex"

module Chalk
    enum TokenType
        Any,
        Str,
        Id,
        LitDec,
        LitBin,
        LitHex,
        OpAdd
        OpSub
        OpMul
        OpDiv
        OpOr
        OpAnd
        OpXor
        KwSprite
        KwInline
        KwFun
        KwU0
        KwU8
        KwU12
        KwVar
        KwIf
        KwElse
        KwWhile
        KwReturn
    end

    class Token
        def initialize(@string : String, @type : TokenType)
        end

        getter string : String
        getter type : TokenType
    end

    class Lexer
        def initialize
            @lexer = Lex::Lexer.new
            @lexer.add_pattern(".", TokenType::Any.value)
            @lexer.add_pattern("\"(\\\\\"|[^\"])*\"",
                               TokenType::Str.value)
            @lexer.add_pattern("[a-zA-Z_][a-zA-Z_0-9]*",
                               TokenType::Id.value)
            @lexer.add_pattern("[0-9]+",
                               TokenType::LitDec.value)
            @lexer.add_pattern("0b[0-1]+",
                               TokenType::LitBin.value)
            @lexer.add_pattern("0x[0-9a-fA-F]+",
                               TokenType::LitHex.value)
            @lexer.add_pattern("\\+", TokenType::OpAdd.value)
            @lexer.add_pattern("-", TokenType::OpSub.value)
            @lexer.add_pattern("\\*", TokenType::OpMul.value)
            @lexer.add_pattern("/", TokenType::OpDiv.value)
            @lexer.add_pattern("&", TokenType::OpAdd.value)
            @lexer.add_pattern("\\|", TokenType::OpOr.value)
            @lexer.add_pattern("^", TokenType::OpXor.value)
            @lexer.add_pattern("sprite", TokenType::KwSprite.value)
            @lexer.add_pattern("inline", TokenType::KwInline.value)
            @lexer.add_pattern("fun", TokenType::KwFun.value)
            @lexer.add_pattern("u0", TokenType::KwU0.value)
            @lexer.add_pattern("u8", TokenType::KwU8.value)
            @lexer.add_pattern("u12", TokenType::KwU12.value)
            @lexer.add_pattern("var", TokenType::KwVar.value)
            @lexer.add_pattern("if", TokenType::KwIf.value)
            @lexer.add_pattern("else", TokenType::KwElse.value)
            @lexer.add_pattern("while", TokenType::KwWhile.value)
            @lexer.add_pattern("return", TokenType::KwReturn.value)
        end

        def lex(string)
            return @lexer.lex(string)
                .select { |t| !t[0][0].whitespace? }
                .map do |tuple|
                    string, id = tuple
                    Token.new(string, TokenType.new(id))
                end
        end
    end
end
