module Chalk
  module Compiler
    # An entry in the symbol table.
    class Entry
    end

    # An entry that represents a function in the symbol table.
    class FunctionEntry < Entry
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
    class VarEntry < Entry
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
        @data = {} of String => Entry
      end

      # Looks up the given *key* first in this table,
      # then in its parent, continuing recursively.
      def []?(key)
        if entry = @data[key]?
          return entry
        end
        return @parent.try &.[key]?
      end

      # Stores an *entry* under the given *key* into this table.
      def []=(key, entry)
        @data[key] = entry
      end

      def to_s(io)
        @parent.try &.to_s(io)
        io << @data.map { |k, v| k + ": " + v.to_s }.join("\n")
      end
    end
  end
end
