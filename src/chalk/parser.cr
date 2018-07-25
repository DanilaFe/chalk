require "./builder.cr"

module Chalk

    abstract class Parser(T)
        abstract def parse?(tokens : Array(Token),
                           index : Int64): Tuple(T, Int64)?
        def parse(tokens : Array(Token),
                  index : Int64): Tuple(T, Int64)
            return parse?(tokens, index).not_nil!
        end

        def transform(&transform : T -> R) forall R
            return TransformParser.new(self, &transform).as(Parser(R))
        end

        def then(other : Parser(R)): Parser(Array(T | R)) forall R
            return NextParser
                .new(self, other)
                .as(Parser(Array(T | R)))
        end
    end

    class TypeParser < Parser(Token)
        def initialize(@type : TokenType)
        end

        def parse?(tokens, index)
            return nil unless index < tokens.size
            return nil unless tokens[index].type == @type
            return { tokens[index], index + 1}
        end
    end

    class TransformParser(T, R) < Parser(R)
        def initialize(@parser : Parser(T), &@block : T -> R)
        end

        def parse?(tokens, index)
            if parsed = @parser.parse?(tokens, index)
                return { @block.call(parsed[0]), parsed[1] }
            end
            return nil
        end
    end

    class OptionalParser(T) < Parser(T?)
        def initialize(@parser : Parser(T))
        end

        def parse?(tokens, index)
            if parsed = @parser.parse?(tokens, index)
                return { parsed[0], parsed[1] }
            end
            return { nil, index }
        end
    end

    class EitherParser(T) < Parser(T)
        def initialize(@parsers : Array(Parser(T)))
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

    class ManyParser(T) < Parser(Array(T))
        def initialize(@parser : Parser(T))
        end

        def parse?(tokens, index)
            many = [] of T
            while parsed = @parser.parse?(tokens, index)
                item, index = parsed
                many << item
            end
            return { many, index }
        end
    end

    class NextParser(T, R) < Parser(Array(T | R))
        def initialize(@first : Parser(T), @second : Parser(R))
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
            return { array, index }
        end
    end

    class PlaceholderParser(T) < Parser(T)
        property parser : Parser(T)?

        def initialize
            @parser = nil
        end

        def parse?(tokens, index)
            @parser.try &.parse(tokens, index)
        end
    end
end
