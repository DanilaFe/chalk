require "./lexer.cr"

module Chalk
  class Instruction
  end

  class LoadInstruction < Instruction
    property register : Int32
    property value : Int32

    def initialize(@register : Int32, @value : Int32)
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

    def initialize(@into : Int32, @from : Int32)
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

    def initialize(@op : TokenType, @into : Int32,
                   @value : Int32)
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

    def initialize(@op : TokenType, @into : Int32, @from : Int32)
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

    def initialize(@up_to : Int32)
    end

    def to_s(io)
      io << "store R"
      @up_to.to_s(16, io)
    end
  end

  class RestoreInstruction < Instruction
    property up_to : Int32

    def initialize(@up_to : Int32)
    end

    def to_s(io)
      io << "restore R"
      @up_to.to_s(16, io)
    end
  end

  class ReturnInstruction < Instruction
    property to_return : Int32

    def initialize(@to_return : Int32)
    end

    def to_s(io)
      io << "return R"
      @to_return.to_s(16, io)
    end
  end
end
