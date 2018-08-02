require "./ir.cr"
require "./emitter.cr"

module Chalk
  module Compiler
    class CodeGenerator
      include Emitter

      RETURN_REG = 14
      STACK_REG  = 13

      property instructions : Array(Ir::Instruction)

      def initialize(table, @function : Trees::TreeFunction)
        @registers = 0
        @instructions = [] of Ir::Instruction
        @table = Table.new table

        @function.params.each do |param|
          @table[param] = VarEntry.new @registers
          @registers += 1
        end
      end

      def generate!(tree, function : Builtin::InlineFunction, table, target, free)
        function.generate!(self, tree.params, table, target, free)
      end

      def generate!(tree, function : Trees::TreeFunction | Builtin::BuiltinFunction, table, target, free)
        start_at = free
        # Move I to stack
        setis
        # Get to correct stack position
        addi STACK_REG
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
        # Move I to stack
        setis
        # Get to correct stack position
        addi STACK_REG
        # Restore
        restore (start_at - 1) unless start_at == 0
        # Get call value into target
        loadr target, RETURN_REG
      end

      def generate!(tree, table, target, free)
        case tree
        when Trees::TreeId
          entry = table[tree.id]?
          raise "Unknown variable" unless entry &&
                                          entry.is_a?(VarEntry)
          loadr target, entry.register
        when Trees::TreeLit
          load target, tree.lit
        when Trees::TreeOp
          generate! tree.left, table, target, free
          generate! tree.right, table, free, free + 1
          opr tree.op, target, free
        when Trees::TreeCall
          entry = table[tree.name]?
          raise "Unknown function" unless entry &&
                                          entry.is_a?(FunctionEntry)
          function = entry.function
          raise "Invalid call" if tree.params.size != function.param_count
          generate! tree, function, table, target, free
        when Trees::TreeBlock
          table = Table.new(table)
          tree.children.each do |child|
            free += generate! child, table, free, free + 1
          end
        when Trees::TreeVar
          entry = table[tree.name]?
          if entry == nil
            entry = VarEntry.new free
            free += 1
            table[tree.name] = entry
          end
          raise "Unknown variable" unless entry.is_a?(VarEntry)
          generate! tree.expr, table, entry.register, free
          return 1
        when Trees::TreeAssign
          entry = table[tree.name]?
          raise "Unknown variable" unless entry &&
                                          entry.is_a?(VarEntry)
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
          generate! tree.rvalue, table, RETURN_REG, free
          ret
        end
        return 0
      end

      def generate!
        generate!(@function.block, @table, -1, @registers)
        return @instructions
      end
    end
  end
end
