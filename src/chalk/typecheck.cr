require "./type"

module Chalk
    module Trees
        # Reducer to check types.
        class TypeChecker < Reducer(Compiler::Type)
            def initialize(@table : Compiler::Table, @return_type : Compiler::Type)
            end

            def reduce(t, children)
                return Compiler::Type::U0
            end

            def reduce(t : TreeCall, children)
                entry = @table[t.name]?
                raise "Unknwon function" unless entry && entry.is_a?(Compiler::FunctionEntry)
                type = entry.function.type
                raise "Invalid parameters" if type.param_types.size != children.size
                children.each_with_index do |child, i|
                    raise "Incompatible parameter" if !child.casts_to?(type.param_types[i])
                end
                return entry.function.type.return_type
            end

            def reduce(t : TreeId, children)
                return Compiler::Type::U8
            end

            def reduce(t : TreeLit, children)
                max_12 = (2 ** 12) - 1
                max_8 = (2 ** 8) - 1
                max_4 = (2 ** 4) - 1
                raise "Number too big" if t.lit > max_12
                return Compiler::Type::U12 if t.lit > max_8
                return Compiler::Type::U8 if t.lit > max_4
                return Compiler::Type::U4
            end

            def reduce(t : TreeOp, children)
                left = children[0]
                right = children[1]
                return left if right.casts_to?(left)
                return right if left.casts_to?(right)
                raise "Invalid operation"
            end

            def reduce(t : TreeAssign | TreeVar, children)
                raise "Invalid assignment" if !children[0].casts_to?(Compiler::Type::U8)
                return Compiler::Type::U0
            end

            def reduce(t : TreeReturn, children)
                raise "Incompatible return type" if !children[0].casts_to?(@return_type)
                return Compiler::Type::U0
            end
        end
    end
end
