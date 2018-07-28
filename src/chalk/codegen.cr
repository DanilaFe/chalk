require "./ir.cr"
require "./emitter.cr"

module Chalk
  class CodeGenerator
    include Emitter

    RETURN_REG = 14
    STACK_REG  = 13

    property instructions : Array(Instruction)

    def initialize(table, @function : TreeFunction)
      @registers = 0
      @instructions = [] of Instruction
      @table = Table.new table

      @function.params.each do |param|
        @table[param] = VarEntry.new @registers
        @registers += 1
      end
    end

    def generate!(tree, function : InlineFunction, table, target, free)
        start = free
        function.generate!(self, tree.params, table, target, free)
    end

    def generate!(tree, function : TreeFunction | BuiltinFunction, table, target, free)
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
      when TreeId
        entry = table[tree.id]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        loadr target, entry.register
      when TreeLit
        load target, tree.lit
      when TreeOp
        generate! tree.left, table, target, free
        generate! tree.right, table, free, free + 1
        opr tree.op, target, free
      when TreeCall
        entry = table[tree.name]?
        raise "Unknown function" unless entry &&
                                        entry.is_a?(FunctionEntry)
        function = entry.function
        raise "Invalid call" if tree.params.size != function.param_count
        generate! tree, function, table, target, free
      when TreeBlock
        table = Table.new(table)
        tree.children.each do |child|
          free += generate! child, table, free, free
        end
      when TreeVar
        entry = table[tree.name]?
        if entry == nil
          entry = VarEntry.new free
          table[tree.name] = entry
        end
        raise "Unknown variable" unless entry.is_a?(VarEntry)
        generate! tree.expr, table, entry.register, free + 1
        return 1
      when TreeAssign
        entry = table[tree.name]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        generate! tree.expr, table, entry.register, free
      when TreeIf
        generate! tree.condition, table, target, free
        sne target, 0
        jump_inst = jr 0

        old_size = @instructions.size
        generate! tree.block, table, free, free + 1
        jump_after = jr 0
        jump_inst.offset = @instructions.size - old_size + 1

        old_size = @instructions.size
        generate! tree.otherwise, table, free, free + 1 if tree.otherwise
        jump_after.offset = @instructions.size - old_size + 1
      when TreeReturn
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
