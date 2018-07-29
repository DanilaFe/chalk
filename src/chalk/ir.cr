require "./lexer.cr"

module Chalk
  class Instruction
    def to_bin(i, index)
      return 0
    end
  end

  class InstructionContext
    property table : Table
    property stack : Int32

    def initialize(@table, @stack)
    end
  end

  class LoadInstruction < Instruction
    property register : Int32
    property value : Int32

    def initialize(@register, @value)
    end

    def to_s(io)
      io << "load R"
      @register.to_s(16, io)
      io << " " << @value
    end

    def to_bin(i, index)
      0x6000 | (@register << 8) | @value
    end
  end

  class LoadRegInstruction < Instruction
    property into : Int32
    property from : Int32

    def initialize(@into, @from)
    end

    def to_s(io)
      io << "loadr R"
      @into.to_s(16, io)
      io << " R"
      @from.to_s(16, io)
    end

    def to_bin(i, index)
      0x8000 | (@into << 8) | (@from << 4)
    end
  end

  class OpInstruction < Instruction
    property op : TokenType
    property into : Int32
    property value : Int32

    def initialize(@op, @into, @value)
    end

    def to_s(io)
      io << "op " << op << " R"
      @into.to_s(16, io)
      io << " " << @value
    end

    def to_bin(i, index)
      case op
      when TokenType::OpAdd
        return 0x7000 | (@into << 8) | @value
      else
        raise "Invalid instruction"
      end
    end
  end

  class OpRegInstruction < Instruction
    property op : TokenType
    property into : Int32
    property from : Int32

    def initialize(@op, @into, @from)
    end

    def to_s(io)
      io << "opr " << op << " R"
      @into.to_s(16, io)
      io << " R"
      @from.to_s(16, io)
    end

    def to_bin(i, index)
      code = 0
      case op
      when TokenType::OpAdd
        code = 4
      when TokenType::OpSub
        code = 5
      when TokenType::OpOr
        code = 1
      when TokenType::OpAnd
        code = 2
      when TokenType::OpXor
        code = 3
      else
        raise "Invalid instruction"
      end
      return 0x8000 | (@into << 8) | (@from << 4) | code
    end
  end

  class StoreInstruction < Instruction
    property up_to : Int32

    def initialize(@up_to)
    end

    def to_s(io)
      io << "store R"
      @up_to.to_s(16, io)
    end

    def to_bin(i, index)
      return 0xf055 | (@up_to << 8)
    end
  end

  class RestoreInstruction < Instruction
    property up_to : Int32

    def initialize(@up_to)
    end

    def to_s(io)
      io << "restore R"
      @up_to.to_s(16, io)
    end

    def to_bin(i, index)
      return 0xf065 | (@up_to << 8)
    end
  end

  class ReturnInstruction < Instruction
    def initialize
    end

    def to_s(io)
      io << "return"
    end

    def to_bin(i, index)
      return 0x00ee
    end
  end

  class JumpRelativeInstruction < Instruction
    property offset : Int32

    def initialize(@offset)
    end

    def to_s(io)
      io << "jr " << @offset
    end

    def to_bin(i, index)
      return 0x1000 | ((@offset + index) * 2 + 0x200)
    end
  end

  class SkipEqInstruction < Instruction
    property left : Int32
    property right : Int32

    def initialize(@left, @right)
    end

    def to_s(io)
      io << "seq R"
      @left.to_s(16, io)
      io << " " << right
    end

    def to_bin(i, index)
      return 0x3000 | (@left << 8) | @right
    end
  end

  class SkipNeInstruction < Instruction
    property left : Int32
    property right : Int32

    def initialize(@left, @right)
    end

    def to_s(io)
      io << "sne R"
      @left.to_s(16, io)
      io << " " << right
    end

    def to_bin(i, index)
      return 0x4000 | (@left << 8) | @right
    end
  end

  class SkipRegEqInstruction < Instruction
    property left : Int32
    property right : Int32

    def initialize(@left, @right)
    end

    def to_s(io)
      io << "seqr R"
      @left.to_s(16, io)
      io << " R"
      @right.to_s(16, io)
    end

    def to_bin(i, index)
      return 0x5000 | (@left << 8) | (@right << 4)
    end
  end

  class SkipRegNeInstruction < Instruction
    property left : Int32
    property right : Int32

    def initialize(@left, @right)
    end

    def to_s(io)
      io << "sner R"
      @left.to_s(16, io)
      io << " R"
      @right.to_s(16, io)
    end

    def to_bin(i, index)
      return 0x9000 | (@left << 8) | (@right << 4)
    end
  end

  class CallInstruction < Instruction
    property name : String

    def initialize(@name)
    end

    def to_s(io)
      io << "call " << @name
    end

    def to_bin(i, index)
      return 0x2000 | (i.table[name]?.as(FunctionEntry).addr * 2 + 0x200)
    end
  end

  class SetIStackInstruction < Instruction
    def to_s(io)
      io << "setis"
    end

    def to_bin(i, index)
      return 0xa000 | (i.stack * 2 + 0x200)
    end
  end

  class AddIRegInstruction < Instruction
    property reg : Int32

    def initialize(@reg)
    end

    def to_s(io)
      io << "addi R"
      reg.to_s(16, io)
    end

    def to_bin(i, index)
      return 0xf000 | (@reg << 8) | 0x1e
    end
  end

  class DrawInstruction < Instruction
    property x : Int32
    property y : Int32
    property height : Int32

    def initialize(@x, @y, @height)
    end

    def to_s(io)
        io << "draw R"
        x.to_s(16, io)
        io << " R"
        y.to_s(16, io)
        io << " " << height
    end

    def to_bin(i, index)
        return 0xd000 | (@x << 8) | (@y << 4) | height
    end
  end

  class AwaitKeyInstruction < Instruction
    property into : Int32

    def initialize(@into)
    end

    def to_s(io)
        io << "getk R"
        @into.to_s(16, io)
    end

    def to_bin(i, index)
        return 0xf00a | (@into << 8)
    end
  end

  class GetFontInstruction < Instruction
    property from : Int32
    
    def initialize(@from)
    end

    def to_s(io)
        io << "font R"
        @from.to_s(16, io)
    end

    def to_bin(i, index)
        return 0xf029 | (@from << 8)
    end
  end

  class SetDelayTimerInstruction < Instruction
    property from : Int32

    def initialize(@from)
    end

    def to_s(io)
        io << "set_delay R"
        @from.to_s(16, io)
    end

    def to_bin(i, index)
        return 0xf015 | (@from << 8)
    end
  end

  class GetDelayTimerInstruction < Instruction
    property into : Int32

    def initialize(@into)
    end

    def to_s(io)
        io << "get_delay R"
        @into.to_s(16, io)
    end

    def to_bin(i, index)
        return 0xf007 | (@into << 8)
    end
  end
end
