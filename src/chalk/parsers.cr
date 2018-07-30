module Chalk
  abstract class BasicParser(T)
    abstract def parse?(tokens : Array(Token),
                        index : Int64) : Tuple(T, Int64)?

    def parse(tokens, index)
      return parse?(tokens, index).not_nil!
    end

    def transform(&transform : T -> R) forall R
      return TransformParser.new(self, &transform).as(BasicParser(R))
    end

    def then(other : BasicParser(R)) : BasicParser(Array(T | R)) forall R
      return NextParser.new(self, other).as(BasicParser(Array(T | R)))
    end
  end

  class TypeParser < BasicParser(Token)
    def initialize(@type : TokenType)
    end

    def parse?(tokens, index)
      return nil unless index < tokens.size
      return nil unless tokens[index].type == @type
      return {tokens[index], index + 1}
    end
  end

  class CharParser < BasicParser(Token)
    def initialize(@char : Char)
    end

    def parse?(tokens, index)
      return nil unless index < tokens.size
      return nil unless (tokens[index].type == TokenType::Any) &&
                        tokens[index].string[0] == @char
      return {tokens[index], index + 1}
    end
  end

  class TransformParser(T, R) < BasicParser(R)
    def initialize(@parser : BasicParser(T), &@block : T -> R)
    end

    def parse?(tokens, index)
      if parsed = @parser.parse?(tokens, index)
        return {@block.call(parsed[0]), parsed[1]}
      end
      return nil
    end
  end

  class OptionalParser(T) < BasicParser(T?)
    def initialize(@parser : BasicParser(T))
    end

    def parse?(tokens, index)
      if parsed = @parser.parse?(tokens, index)
        return {parsed[0], parsed[1]}
      end
      return {nil, index}
    end
  end

  class EitherParser(T) < BasicParser(T)
    def initialize(@parsers : Array(BasicParser(T)))
    end

    def parse?(tokens, index)
      @parsers.each do |parser|
        if parsed = parser.parse?(tokens, index)
          return parsed
        end
      end
      return nil
    end
  end

  class ManyParser(T) < BasicParser(Array(T))
    def initialize(@parser : BasicParser(T))
    end

    def parse?(tokens, index)
      many = [] of T
      while parsed = @parser.parse?(tokens, index)
        item, index = parsed
        many << item
      end
      return {many, index}
    end
  end

  class DelimitedParser(T, R) < BasicParser(Array(T))
    def initialize(@parser : BasicParser(T), @delimiter : BasicParser(R))
    end

    def parse?(tokens, index)
      array = [] of T
      first = @parser.parse?(tokens, index)
      return {array, index} unless first
      first_value, index = first
      array << first_value
      while delimiter = @delimiter.parse?(tokens, index)
        _, new_index = delimiter
        new = @parser.parse?(tokens, new_index)
        break unless new
        new_value, index = new
        array << new_value
      end

      return {array, index}
    end
  end

  class NextParser(T, R) < BasicParser(Array(T | R))
    def initialize(@first : BasicParser(T), @second : BasicParser(R))
    end

    def parse?(tokens, index)
      first = @first.parse?(tokens, index)
      return nil unless first
      first_value, index = first

      second = @second.parse?(tokens, index)
      return nil unless second
      second_value, index = second

      array = Array(T | R).new
      array << first_value << second_value
      return {array, index}
    end
  end

  class PlaceholderParser(T) < BasicParser(T)
    property parser : BasicParser(T)?

    def initialize
      @parser = nil
    end

    def parse?(tokens, index)
      @parser.try &.parse?(tokens, index)
    end
  end
end
