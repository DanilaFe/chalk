require "./lexer.cr"

module Chalk
  class Instruction
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
  end

  class StoreInstruction < Instruction
    property up_to : Int32

    def initialize(@up_to)
    end

    def to_s(io)
      io << "store R"
      @up_to.to_s(16, io)
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
  end

  class ReturnInstruction < Instruction
    def initialize()
    end

    def to_s(io)
      io << "return"
    end
  end

  class JumpEqInstruction < Instruction
    property offset : Int32
    property left : Int32
    property right : Int32

    def initialize(@offset, @left, @right)
    end

    def to_s(io)
      io << "jeq " << offset << " R"
      @left.to_s(16, io)
      io << " " << right
    end
  end

  class JumpRelativeInstruction < Instruction
    property offset : Int32

    def initialize(@offset)
    end

    def to_s(io)
      io << "jr " << @offset
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
  end

  class CallInstruction < Instruction
    property name : String

    def initialize(@name)
    end

    def to_s(io)
      io << "call " << @name
    end
  end
  
  class SetIInstruction < Instruction
    property value : Int32

    def initialize(@value)
    end

    def to_s(io)
      io << "seti " << @value
    end
  end

  class SetIStackInstruction < Instruction
    def to_s(io)
      io << "setis"
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
  end
end
