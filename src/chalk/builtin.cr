module Chalk
  module Builtin
    # A normal function (i.e., a "call" is generated for it)
    # that is provided by chalk's standard library, and therefore
    # has predefined output.
    abstract class BuiltinFunction
      # Gets the number of parameters this function has.
      getter param_count : Int32

      # Creates a new function with *param_count* parameters.
      def initialize(@param_count)
      end

      # Uses the given `Compiler::Emitter` to output code.
      abstract def generate!(codegen)
      # Gets the `Compiler::FunctionType` of this function.
      abstract def type
    end

    # A function to which a call is not generated. This function
    # is copied everywhere a call to it occurs. Besides this, the
    # function also accepts trees rather than register numbers,
    # and therefore can accept and manipulate trees.
    abstract class InlineFunction
      # Gets the number of parameters this function has.
      getter param_count : Int32

      # Creates a new function with *param_count* parameters.
      def initialize(@param_count)
      end

      # Generates code like `Compiler::CodeGenerator` would.
      # The *codegen* parameter is used to emit instructions,
      # the *params* are trees that are being passed as arguments.
      # See `Compiler::CodeGenerator#generate!` for what the other parameters mean.
      abstract def generate!(codegen, params, table, target, free)
      # Gets the `Compiler::FunctionType` of this function.
      abstract def type
    end
  end
end
