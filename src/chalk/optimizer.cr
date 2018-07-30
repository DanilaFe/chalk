module Chalk
  class Optimizer
     private def check_dead(inst)
      if inst.is_a?(LoadRegInstruction)
        return inst.from == inst.into
      end
      return false
    end

    private def optimize!(instructions, range)
      offset = 0
      range.each do |index|
        if check_dead(instructions[index + offset])
          instructions.delete_at(index + offset)
          offset -= 1
        end
      end
      return offset
    end

    def optimize(instructions)
      instructions = instructions.dup
      block_boundaries = [instructions.size]
      instructions.each_with_index do |inst, i|
        if inst.is_a?(JumpRelativeInstruction)
          block_boundaries << (inst.offset + i)
        end
      end
      block_boundaries.sort!

      previous = 0
      offset = 0
      block_boundaries.each do |boundary|
        range = (previous + offset)...(boundary + offset)
        offset += optimize!(instructions, range)
        previous = boundary
      end
      return instructions
    end
  end
end
