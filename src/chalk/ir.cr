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
    property to_return : Int32

    def initialize(@to_return)
    end

    def to_s(io)
      io << "return R"
      @to_return.to_s(16, io)
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

  class JumpEqRegInstruction < Instruction
    property offset : Int32
    property left : Int32
    property right : Int32

    def initialize(@offset, @left, @right)
    end

    def to_s(io)
      io << "jeq " << offset << " R"
      @left.to_s(16, io)
      io << " R"
      @right.to_s(16, io)
    end
  end
  
end
