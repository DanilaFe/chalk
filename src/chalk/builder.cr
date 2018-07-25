require "./lexer.cr"
require "./parsers.cr"

module Chalk
  module Builder
    def type(type) : BasicParser(Token)
      return TypeParser.new(type).as(BasicParser(Token))
    end

    def char(type) : BasicParser(Token)
      return CharParser.new(type).as(BasicParser(Token))
    end

    def transform(parser : BasicParser(T), &transform : T -> R) forall T, R
      return TransformParser.new(parser, &transform).as(BasicParser(R))
    end

    def optional(parser : BasicParser(T)) : BasicParser(T?) forall T
      return OptionalParser.new(parser).as(BasicParser(T?))
    end

    def either(*args : BasicParser(T)) : BasicParser(T) forall T
      return EitherParser.new(args.to_a).as(BasicParser(T))
    end

    def many(parser : BasicParser(T)) : BasicParser(Array(T)) forall T
      return ManyParser.new(parser).as(BasicParser(Array(T)))
    end

    def delimited(parser : BasicParser(T), delimiter : BasicParser(R)) : BasicParser(Array(T)) forall T, R
      return DelimitedParser.new(parser, delimiter).as(BasicParser(Array(T)))
    end

    def then(first : BasicParser(T), second : BasicParser(R)) forall T, R
      return NextParser.new(first, second).as(BasicParser(Array(T | R)))
    end
  end
end
