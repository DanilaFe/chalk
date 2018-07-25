require "./lexer.cr"
require "./parser.cr"

module Chalk
    def self.type(type): Parser(Token)
        return TypeParser.new(type).as(Parser(Token))
    end

    def self.transform(parser : Parser(T), &transform : T -> R) forall T, R
        return TransformParser.new(parser, &transform).as(Parser(R))
    end

    def self.optional(parser : Parser(T)): Parser(T?) forall T
        return OptionalParser.new(parser).as(Parser(T?))
    end

    def self.either(*args : Parser(T)): Parser(T) forall T
        return EitherParser.new(args.to_a).as(Parser(T))
    end

    def self.many(parser : Parser(T)): Parser(Array(T)) forall T
        return ManyParser.new(parser).as(Parser(Array(T)))
    end

    def self.then(first : Parser(T), second : Parser(R)) forall T, R
        return NextParser.new(first, second).as(Parser(Array(T | R)))
    end
end
