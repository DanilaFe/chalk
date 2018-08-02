module Chalk
  module Compiler
    class Optimizer
      private def check_dead(inst)
        if inst.is_a?(Ir::LoadRegInstruction)
          return inst.from == inst.into
        end
        return false
      end

      private def optimize!(instructions, range, deletions, deletions_at)
        range.each do |index|
          if check_dead(instructions[index])
            deletions << index
          end
          deletions_at[index] = deletions.size
        end
      end

      def optimize(instructions)
        instructions = instructions.dup
        block_boundaries = [instructions.size]
        instructions.each_with_index do |inst, i|
          if inst.is_a?(Ir::JumpRelativeInstruction)
            block_boundaries << i
            block_boundaries << (inst.offset + i)
          end
        end
        block_boundaries.uniq!.sort!

        previous = 0
        deletions = [] of Int32
        deletions_at = {} of Int32 => Int32
        block_boundaries.each do |boundary|
          range = previous...boundary
          optimize!(instructions, range, deletions, deletions_at)
          previous = boundary
        end

        instructions.each_with_index do |inst, i|
          next if !inst.is_a?(Ir::JumpRelativeInstruction)
          jump_to = inst.offset + i
          next unless deletions_at[jump_to]?
          deletions_offset = deletions_at[i] - deletions_at[jump_to]
          inst.offset += deletions_offset
        end

        deletions.reverse!
        deletions.each do |i|
          instructions.delete_at i
        end

        return instructions
      end
    end
  end
end
