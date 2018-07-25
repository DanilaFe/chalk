require "./tree.cr"

module Chalk
    class PrintVisitor < Visitor
        def initialize
            @indent = 0
        end

        def print_indent
            @indent.times do
                STDOUT << "  "
            end
        end

        def visit(id : TreeId)
            print_indent
            puts id.id
        end

        def visit(lit : TreeLit)
            print_indent
            puts lit.lit
        end

        def visit(op : TreeOp)
            print_indent
            STDOUT << "[op] "
            puts op.op
            @indent += 1
        end

        def finish(op : TreeOp)
            @indent -= 1
        end

        def visit(function : TreeFunction)
            print_indent
            STDOUT << "[function] " << function.name << "( "
            function.params.each do |param|
                STDOUT << param << " "
            end
            puts ")"
            @indent += 1
        end

        def finish(function : TreeFunction)
            @indent -= 1
        end

        macro forward(text, type)
            def visit(tree : {{type}})
                print_indent
                puts {{text}}
                @indent += 1
            end

            def finish(tree : {{type}})
                @indent -= 1
            end
        end

        forward("[call]", TreeCall)
        forward("[block]", TreeBlock)
        forward("[var]", TreeVar)
        forward("[assign]", TreeAssign)
        forward("[if]", TreeIf)
        forward("[while]", TreeWhile)
        forward("[return]", TreeReturn)
    end
end
