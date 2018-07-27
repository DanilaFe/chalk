require "./ir.cr"

module Chalk
  class CodeGenerator
    def initialize(table, @function : TreeFunction)
      @register = 0
      @instructions = [] of Instruction
      @table = Table.new table

      @function.params.each do |param|
        @table[param] = VarEntry.new @register
        @register += 1
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
      inst = OpRegInstruction.new op, into, from
      @instructions << inst
      return inst
    end

    private def jeq(rel, l, r)
      inst = JumpEqRegInstruction.new rel, l, r
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

    private def ret(reg)
      inst =  ReturnInstruction.new reg
      @instructions << inst
      return inst
    end

    def generate!(tree, target)
      case tree
      when TreeId
        entry = @table[tree.id]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        loadr target, entry.register
      when TreeLit
        load target, tree.lit
      when TreeOp
        into = @register
        @register += 1
        generate! tree.left, target
        generate! tree.right, into
        @register -= 1
        op tree.op, target, into
      when TreeBlock
        register = @register
        tree.children.each do |child|
          generate! child, @register
        end
        @register = register
      when TreeVar
        entry = @table[tree.name]?
        if entry == nil
          entry = VarEntry.new @register
          @register += 1
          @table[tree.name] = entry
        end
        raise "Unknown variable" unless entry.is_a?(VarEntry)
        generate! tree.expr, entry.register
      when TreeAssign
        entry = @table[tree.name]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        generate! tree.expr, entry.register
      when TreeIf
        cond_target = @register
        @register += 1

        generate! tree.condition, cond_target
        load cond_target + 1, 0
        jump_inst = jeq 0, cond_target, cond_target + 1
        @register -= 1

        old_size = @instructions.size
        generate! tree.block, @register
        jump_inst.offset = @instructions.size - old_size + 1

        generate! tree.otherwise, @register if tree.otherwise
      when TreeReturn
        into = @register
        @register += 1
        generate! tree.rvalue, into
        @register -= 1
        ret into
      end
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
        if inst.is_a?(JumpEqRegInstruction) ||
           inst.is_a?(JumpEqInstruction)
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
      generate!(@function.block, @register)
      optimize!
      return @instructions
    end
  end
end
