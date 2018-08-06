require "./ir.cr"
require "./emitter.cr"

module Chalk
  module Compiler
    # A class that converts a tree into the corresponding
    # intermediate representation, without optimizing.
    class CodeGenerator
      include Emitter

      # Gets the instructions currently emitted by this code generator.
      getter instructions

      # Creates a new compiler with the given symbol *table*
      # and *function* for which code should be generated.
      def initialize(table, @function : Trees::TreeFunction)
        @registers = 0
        @instructions = [] of Ir::Instruction
        @table = Table.new table

        @function.params.each do |param|
          @table.set_var param, VarEntry.new @registers
          @registers += 1
        end
      end

      # Generates code for an inline function, with the given *tree* being the `Trees::TreeCall`
      # that caused the function call. The other parameters are as described in the more general
      # `#generate!` call.
      def generate!(tree, function : Builtin::InlineFunction, table, target, free)
        function.generate!(self, tree.params, table, target, free)
      end

      # Generates code for a tree or a builtin function (that is, a call is actually necessary).
      # I is set to the current stack pointer, the registers are stored, and the call is made.
      # The registers are then restored. The other parameters are as described in the more general
      # `#generate!` call.
      def generate!(tree, function : Trees::TreeFunction | Builtin::BuiltinFunction, table, target, free)
        start_at = free
        to_stack
        # Store variables
        store (start_at - 1) unless start_at == 0
        # Increment I and stack position
        load free, start_at
        opr TokenType::OpAdd, STACK_REG, free
        addi free

        # Calculate the parameters
        tree.params.each do |param|
          generate! param, table, free, free + 1
          free += 1
        end
        # Call the function
        tree.params.size.times do |time|
          loadr time, time + start_at
        end
        call tree.name

        # Reduce stack pointer
        load free, start_at
        opr TokenType::OpSub, STACK_REG, free
        to_stack
        # Restore
        restore (start_at - 1) unless start_at == 0
        # Get call value into target
        loadr target, RETURN_REG
      end

      # Generates code for a *tree*, using a symbol *table*
      # housing all the names for identifiers in the code.
      # The result is stored into the *target* register,
      # and the *free* register is the next register into
      # which a value can be stored for "scratch work".
      def generate!(tree, table, target, free)
        case tree
        when Trees::TreeId
          entry = table.get_var? tree.id
          raise "Unknown variable" unless entry
          loadr target, entry.register
        when Trees::TreeLit
          load target, tree.lit
        when Trees::TreeOp
          generate! tree.left, table, target, free
          generate! tree.right, table, free, free + 1
          opr tree.op, target, free
        when Trees::TreeCall
          entry = table.get_function?(tree.name).not_nil!
          raise "Unknown function" unless entry.is_a?(FunctionEntry)
          generate! tree, entry.function, table, target, free
        when Trees::TreeBlock
          table = Table.new(table)
          tree.children.each do |child|
            free += generate! child, table, THROWAWAY_REG, free
          end
        when Trees::TreeVar
          entry = table.get_var? tree.name
          if entry == nil
            entry = VarEntry.new free
            free += 1
            table.set_var tree.name, entry
          end
          generate! tree.expr, table, entry.as(VarEntry).register, free
          return 1
        when Trees::TreeAssign
          entry = table.get_var? tree.name
          raise "Unknown variable" unless entry
          generate! tree.expr, table, entry.register, free
        when Trees::TreeIf
          generate! tree.condition, table, free, free + 1
          sne free, 0
          jump_inst = jr 0

          old_size = @instructions.size
          generate! tree.block, table, free, free + 1
          jump_after = jr 0
          jump_inst.offset = @instructions.size - old_size + 1

          old_size = @instructions.size
          generate! tree.otherwise, table, free, free + 1 if tree.otherwise
          jump_after.offset = @instructions.size - old_size + 1
        when Trees::TreeWhile
          before_cond = @instructions.size
          generate! tree.condition, table, free, free + 1
          sne free, 0
          cond_jump = jr 0

          old_size = @instructions.size
          generate! tree.block, table, free, free + 1
          after_jump = jr 0

          cond_jump.offset = @instructions.size - old_size + 1
          after_jump.offset = before_cond - instructions.size + 1
        when Trees::TreeReturn
          generate! tree.rvalue, table, free, free + 1
          loadr RETURN_REG, free
          ret
        end
        return 0
      end

      # Generates code for the function that was given to it.
      def generate!
        generate!(@function.block, @table, 0, @registers)
        return @instructions
      end
    end
  end
end
