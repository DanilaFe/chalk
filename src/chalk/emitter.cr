module Chalk
  module Emitter
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

    private def setis
      inst = SetIStackInstruction.new
      @instructions << inst
      return inst
    end

    private def addi(reg)
      inst = AddIRegInstruction.new reg
      @instructions << inst
      return inst
    end
  end
end
