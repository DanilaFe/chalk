require "./lexer.cr"
require "./parsers.cr"

module Chalk
  module ParserCombinators
    module ParserBuilder
      # Creates a parser for a given token type.
      def type(type) : BasicParser(Compiler::Token)
        return TypeParser.new(type).as(BasicParser(Compiler::Token))
      end

      # Creates a parser for a specific character.
      def char(type) : BasicParser(Compiler::Token)
        return CharParser.new(type).as(BasicParser(Compiler::Token))
      end

      # Creates a parser that transforms a value according to a block.
      def transform(parser : BasicParser(T), &transform : T -> R) forall T, R
        return TransformParser.new(parser, &transform).as(BasicParser(R))
      end

      # Creates a parser that allows for failure to match.
      def optional(parser : BasicParser(T)) : BasicParser(T?) forall T
        return OptionalParser.new(parser).as(BasicParser(T?))
      end

      # Creates a parser that tries several parsers in sequence until one succeeds.
      def either(*args : BasicParser(T)) : BasicParser(T) forall T
        return EitherParser.new(args.to_a).as(BasicParser(T))
      end

      # Creates a parser that parses one or more of the given parsers.
      def many(parser : BasicParser(T)) : BasicParser(Array(T)) forall T
        return ManyParser.new(parser).as(BasicParser(Array(T)))
      end

      # Creates a parser that parses one parser delimited by another.
      def delimited(parser : BasicParser(T), delimiter : BasicParser(R)) : BasicParser(Array(T)) forall T, R
        return DelimitedParser.new(parser, delimiter).as(BasicParser(Array(T)))
      end

      # Creates a parser that parses one parser, then the next.
      def then(first : BasicParser(T), second : BasicParser(R)) forall T, R
        return NextParser.new(first, second).as(BasicParser(Array(T | R)))
      end
    end
  end
end
