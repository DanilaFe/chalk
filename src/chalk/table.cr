module Chalk
  module Compiler
    # An entry that represents a function in the symbol table.
    class FunctionEntry
      # Gets the function stored in this entry.
      getter function
      # Gets the address in code of this function.
      getter addr
      # Sets the address in code of this function.
      setter addr

      def initialize(@function : Trees::TreeFunction | Builtin::BuiltinFunction | Builtin::InlineFunction,
                     @addr = -1)
      end

      def to_s(io)
        io << "[function]"
      end
    end

    # An entry that represents a variable in the symbol table.
    class VarEntry
      # Gets the register occupied by the variable
      # in this entry.
      getter register

      def initialize(@register : Int32)
      end

      def to_s(io)
        io << "[variable] " << "(R" << @register.to_s(16) << ")"
      end
    end

    # A symbol table.
    class Table
      # Gets the parent of this table.
      getter parent

      def initialize(@parent : Table? = nil)
        @functions = {} of String => FunctionEntry
        @vars = {} of String => VarEntry
      end

      macro table_functions(name)
          def get_{{name}}?(key)
             @{{name}}s[key]? || @parent.try &.get_{{name}}?(key)
          end

          def set_{{name}}(key, value)
             @{{name}}s[key] = value
          end
      end

      table_functions function
      table_functions var

      def to_s(io)
        @parent.try &.to_s(io)
        io << @data.map { |k, v| k + ": " + v.to_s }.join("\n")
      end
    end
  end
end
