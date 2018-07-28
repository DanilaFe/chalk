require "./ir.cr"

module Chalk
  class CodeGenerator
    RETURN_REG = 14
    STACK_REG = 13

    def initialize(table, @function : TreeFunction)
      @registers = 0
      @instructions = [] of Instruction
      @table = Table.new table

      @function.params.each do |param|
        @table[param] = VarEntry.new @registers
        @registers += 1
      end
    end

    private def load(into, value)
      inst = LoadInstruction.new into, value.to_i32
      @instructions << inst
      return inst
    end

    private def loadr(into, from)
      inst = LoadRegInstruction.new into, from
      @instructions << inst
      return inst
    end

    private def op(op, into, from)
      inst = OpInstruction.new op, into, from
      @instructions << inst
      return inst
    end

    private def opr(op, into, from)
      inst = OpRegInstruction.new op, into, from
      @instructions << inst
      return inst
    end

    private def sne(l, r)
      inst = SkipNeInstruction.new l, r
      @instructions << inst
      return inst
    end

    private def jr(o)
      inst = JumpRelativeInstruction.new o
      @instructions << inst
      return inst
    end

    private def store(up_to)
      inst = StoreInstruction.new up_to
      @instructions << inst
      return inst
    end

    private def restore(up_to)
      inst = RestoreInstruction.new up_to
      @instructions << inst
      return inst
    end

    private def ret
      inst = ReturnInstruction.new
      @instructions << inst
      return inst
    end

    private def call(func)
      inst = CallInstruction.new func
      @instructions << inst
      return inst
    end

    def setis
      inst = SetIStackInstruction.new 
      @instructions << inst
      return inst
    end

    def addi(reg)
      inst = AddIRegInstruction.new reg
      @instructions << inst
      return inst
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
        raise "Invalid call" if tree.params.size != entry.function.params.size

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

    private def check_dead(inst)
      if inst.is_a?(LoadRegInstruction)
        return inst.from == inst.into
      end
      return false
    end

    private def optimize!(range)
      offset = 0
      range.each do |index|
        if check_dead(@instructions[index + offset])
          @instructions.delete_at(index + offset)
          offset -= 1
        end
      end
      return offset
    end

    private def optimize!
      block_boundaries = [ @instructions.size ]
      @instructions.each_with_index do |inst, i|
        if inst.is_a?(JumpRelativeInstruction)
            block_boundaries << (inst.offset + i)
        end
      end
      block_boundaries.sort!

      previous = 0
      offset = 0
      block_boundaries.each do |boundary|
        range = (previous + offset)...(boundary + offset)
        offset += optimize!(range)
        previous = boundary
      end
    end

    def generate!
      generate!(@function.block, @table, -1, @registers)
      optimize!
      return @instructions
    end
  end
end
