module Chalk
  module Compiler
    module Emitter
      def load(into, value)
        inst = Ir::LoadInstruction.new into, value.to_i32
        @instructions << inst
        return inst
      end

      def loadr(into, from)
        inst = Ir::LoadRegInstruction.new into, from
        @instructions << inst
        return inst
      end

      def op(op, into, from)
        inst = Ir::OpInstruction.new op, into, from
        @instructions << inst
        return inst
      end

      def opr(op, into, from)
        inst = Ir::OpRegInstruction.new op, into, from
        @instructions << inst
        return inst
      end

      def sne(l, r)
        inst = Ir::SkipNeInstruction.new l, r
        @instructions << inst
        return inst
      end

      def jr(o)
        inst = Ir::JumpRelativeInstruction.new o
        @instructions << inst
        return inst
      end

      def store(up_to)
        inst = Ir::StoreInstruction.new up_to
        @instructions << inst
        return inst
      end

      def restore(up_to)
        inst = Ir::RestoreInstruction.new up_to
        @instructions << inst
        return inst
      end

      def ret
        inst = Ir::ReturnInstruction.new
        @instructions << inst
        return inst
      end

      def call(func)
        inst = Ir::CallInstruction.new func
        @instructions << inst
        return inst
      end

      def setis
        inst = Ir::SetIStackInstruction.new
        @instructions << inst
        return inst
      end

      def addi(reg)
        inst = Ir::AddIRegInstruction.new reg
        @instructions << inst
        return inst
      end
    end
  end
end
