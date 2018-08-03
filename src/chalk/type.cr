module Chalk
    module Compiler
        # Possible types of values in chalk
        enum Type
            U0
            U4
            U8
            U12

            # Checks if one value can be cast to another.
            def casts_to?(other)
                return false if other == Type::U0 || self == Type::U0
                return other.value >= self.value
            end
        end

        # A type of a function.
        class FunctionType
            # Gets the types of the function's parameters.
            getter param_types
            # Gets the return type of the function.
            getter return_type

            def initialize(@param_types : Array(Type), @return_type : Type)
            end

            def to_s(io)
                io << "("
                io << param_types.map(&.to_s).join(", ")
                io << ") -> "
                return_type.to_s(io)
            end
        end
    end
end
