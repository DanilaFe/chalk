module Chalk
    class Optimizer
        def initialize(instructions : Array(Instruction))
            @instructions = instructions.dup
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
    end
end
