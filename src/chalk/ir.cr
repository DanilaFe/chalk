require "./lexer.cr"

module Chalk
  module Ir
    # Base instruction class.
    class Instruction
      # Converts the instruction to binary, using
      # A table for symbol lookups, the stack position,
      # and the inex of the instruction.
      def to_bin(table, stack, index)
        return 0
      end
    end

    # Instruction to load a value into a register.
    class LoadInstruction < Instruction
      def initialize(@register : Int32, @value : Int32)
      end

      def to_s(io)
        io << "load R"
        @register.to_s(16, io)
        io << " " << @value
      end

      def to_bin(table, stack, index)
        0x6000 | (@register << 8) | @value
      end
    end

    # Instruction to load a register into another register.
    class LoadRegInstruction < Instruction
      # Gets the register being written to.
      getter into
      # Gets the register being used as right-hand operand.
      getter from

      def initialize(@into : Int32, @from : Int32)
      end

      def to_s(io)
        io << "loadr R"
        @into.to_s(16, io)
        io << " R"
        @from.to_s(16, io)
      end

      def to_bin(table, stack, index)
        0x8000 | (@into << 8) | (@from << 4)
      end
    end

    # Instruction to perform an operation on a register and a value,
    # storing the output back into the register.
    class OpInstruction < Instruction
      def initialize(@op : Compiler::TokenType, @into : Int32, @value : Int32)
      end

      def to_s(io)
        io << "op " << @op << " R"
        @into.to_s(16, io)
        io << " " << @value
      end

      def to_bin(table, stack, index)
        case @op
        when Compiler::TokenType::OpAdd
          return 0x7000 | (@into << 8) | @value
        else
          raise "Invalid instruction"
        end
      end
    end

    # Instruction to perform an operation on a register and another register,
    # storing the output back into left hand register.
    class OpRegInstruction < Instruction
      def initialize(@op : Compiler::TokenType, @into : Int32, @from : Int32)
      end

      def to_s(io)
        io << "opr " << @op << " R"
        @into.to_s(16, io)
        io << " R"
        @from.to_s(16, io)
      end

      def to_bin(table, stack, index)
        code = 0
        case @op
        when Compiler::TokenType::OpAdd
          code = 4
        when Compiler::TokenType::OpSub
          code = 5
        when Compiler::TokenType::OpOr
          code = 1
        when Compiler::TokenType::OpAnd
          code = 2
        when Compiler::TokenType::OpXor
          code = 3
        else
          raise "Invalid instruction"
        end
        return 0x8000 | (@into << 8) | (@from << 4) | code
      end
    end

    # Instruction to write registers to memory at address I.
    # The *up_to* parameter specifies the highest register
    # that should be stored.
    class StoreInstruction < Instruction
      def initialize(@up_to : Int32)
      end

      def to_s(io)
        io << "store R"
        @up_to.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf055 | (@up_to << 8)
      end
    end

    # Instruction to read registers from memory at address I.
    # The *up_to* parameter specifies the highest register
    # that should be read into.
    class RestoreInstruction < Instruction
      def initialize(@up_to : Int32)
      end

      def to_s(io)
        io << "restore R"
        @up_to.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf065 | (@up_to << 8)
      end
    end

    # Instruction to return from a call.
    class ReturnInstruction < Instruction
      def initialize
      end

      def to_s(io)
        io << "return"
      end

      def to_bin(table, stack, index)
        return 0x00ee
      end
    end

    # Instruction to jump relative to its own position.
    class JumpRelativeInstruction < Instruction
      # Gets the offset of this instruction.
      getter offset
      # Sets the offset of this instruction
      setter offset

      def initialize(@offset : Int32)
      end

      def to_s(io)
        io << "jr " << @offset
      end

      def to_bin(table, stack, index)
        return 0x1000 | ((@offset + index) * 2 + 0x200)
      end
    end

    # Instruction to skip the next instruction if
    # the left-hand register is equal to the right-hand value.
    class SkipEqInstruction < Instruction
      def initialize(@left : Int32, @right : Int32)
      end

      def to_s(io)
        io << "seq R"
        @left.to_s(16, io)
        io << " " << @right
      end

      def to_bin(table, stack, index)
        return 0x3000 | (@left << 8) | @right
      end
    end

    # Instruction to skip the next instruction if
    # the left-hand register is not equal to the right-hand value.
    class SkipNeInstruction < Instruction
      def initialize(@left : Int32, @right : Int32)
      end

      def to_s(io)
        io << "sne R"
        @left.to_s(16, io)
        io << " " << @right
      end

      def to_bin(table, stack, index)
        return 0x4000 | (@left << 8) | @right
      end
    end

    # Instruction to skip the next instruction if
    # the left-hand register is equal to the right-hand register.
    class SkipRegEqInstruction < Instruction
      def initialize(@left : Int32, @right : Int32)
      end

      def to_s(io)
        io << "seqr R"
        @left.to_s(16, io)
        io << " R"
        @right.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0x5000 | (@left << 8) | (@right << 4)
      end
    end

    # Instruction to skip the next instruction if
    # the left-hand register is not equal to the right-hand register.
    class SkipRegNeInstruction < Instruction
      def initialize(@left : Int32, @right : Int32)
      end

      def to_s(io)
        io << "sner R"
        @left.to_s(16, io)
        io << " R"
        @right.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0x9000 | (@left << 8) | (@right << 4)
      end
    end

    # Instruction to call a function by name.
    class CallInstruction < Instruction
      # Gets the name of the function being called.
      getter name

      def initialize(@name : String)
      end

      def to_s(io)
        io << "call " << @name
      end

      def to_bin(table, stack, index)
        return 0x2000 | (table[name]?.as(Compiler::FunctionEntry).addr * 2 + 0x200)
      end
    end

    # Instruction to set I to the base position of the stack.
    class SetIStackInstruction < Instruction
      def to_s(io)
        io << "setis"
      end

      def to_bin(table, stack, index)
        return 0xa000 | (stack * 2 + 0x200)
      end
    end

    # Instruction to add a register to I.
    class AddIRegInstruction < Instruction
      def initialize(@reg : Int32)
      end

      def to_s(io)
        io << "addi R"
        @reg.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf000 | (@reg << 8) | 0x1e
      end
    end

    # Instruction to draw on screen.
    # The x and y coordinates specify the position of the sprite,
    # and the height gives the height of the sprite.
    class DrawInstruction < Instruction
      def initialize(@x : Int32, @y : Int32, @height : Int32)
      end

      def to_s(io)
        io << "draw R"
        @x.to_s(16, io)
        io << " R"
        @y.to_s(16, io)
        io << " " << @height
      end

      def to_bin(table, stack, index)
        return 0xd000 | (@x << 8) | (@y << 4) | @height
      end
    end

    # Instruction to await a key press and store it into a register.
    class AwaitKeyInstruction < Instruction
      def initialize(@into : Int32)
      end

      def to_s(io)
        io << "getk R"
        @into.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf00a | (@into << 8)
      end
    end

    # Instruction to set I to the font given by the value
    # of a register.
    class GetFontInstruction < Instruction
      def initialize(@from : Int32)
      end

      def to_s(io)
        io << "font R"
        @from.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf029 | (@from << 8)
      end
    end

    # Instruction to set the delay timer to the value
    # of the given register.
    class SetDelayTimerInstruction < Instruction
      def initialize(@from : Int32)
      end

      def to_s(io)
        io << "set_delay R"
        @from.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf015 | (@from << 8)
      end
    end

    # Instruction to get the delay timer, and store
    # the value into the given register.
    class GetDelayTimerInstruction < Instruction
      def initialize(@into : Int32)
      end

      def to_s(io)
        io << "get_delay R"
        @into.to_s(16, io)
      end

      def to_bin(table, stack, index)
        return 0xf007 | (@into << 8)
      end
    end
  end
end
