module Chalk
  module Compiler
    # Module to emit instructions and store
    # them into an existing array.
    module Emitter
      # Emits an instruction to load a *value* into a register, *into*.
      def load(into, value)
        inst = Ir::LoadInstruction.new into, value.to_i32
        @instructions << inst
        return inst
      end

      # Emits an instruction to load a register, *from*, into
      # another register, *into*
      def loadr(into, from)
        inst = Ir::LoadRegInstruction.new into, from
        @instructions << inst
        return inst
      end

      # Emits an instruction that's converted
      # to an operation, *op* that mutates the register, *into*,
      # with the right hand operand *from*
      def op(op, into, from)
        inst = Ir::OpInstruction.new op, into, from
        @instructions << inst
        return inst
      end

      # Emits an instruction that's converted
      # to an operation, *op*, that mutates the register, *into*,
      # with the right hand operand (a register), *from*
      def opr(op, into, from)
        inst = Ir::OpRegInstruction.new op, into, from
        @instructions << inst
        return inst
      end

      # Emits a "skip next instruction if not equal"
      # instruction. The left hand side is a register,
      # an the right hand side is a value.
      def sne(l, r)
        inst = Ir::SkipNeInstruction.new l, r
        @instructions << inst
        return inst
      end

      # Emits an instruction to jump relative to
      # where the instruction is.
      # ```
      # jr 0 # Infinite loop
      # jr -1 # Run previous instruction
      # jr 1 # pretty much a no-op.
      # ```
      def jr(o)
        inst = Ir::JumpRelativeInstruction.new o
        @instructions << inst
        return inst
      end

      # Emits instruction that stores register 0 through *up_to* into
      # memory at address I.
      def store(up_to)
        inst = Ir::StoreInstruction.new up_to
        @instructions << inst
        return inst
      end

      # Emits instruction that loads values from address I into
      # register 0 through *up_t*
      def restore(up_to)
        inst = Ir::RestoreInstruction.new up_to
        @instructions << inst
        return inst
      end

      # Emits a return instruction.
      def ret
        inst = Ir::ReturnInstruction.new
        @instructions << inst
        return inst
      end

      # Emits an instruction to call
      # the given function name.
      def call(func)
        inst = Ir::CallInstruction.new func
        @instructions << inst
        return inst
      end

      # Emits instruction to set I
      # to the baste stack location. The stack
      # pointer will need to be added to I
      # to get the next available stack slot.
      def setis
        inst = Ir::SetIStackInstruction.new
        @instructions << inst
        return inst
      end

      # Emits instruction to add the value of a
      # register to I
      def addi(reg)
        inst = Ir::AddIRegInstruction.new reg
        @instructions << inst
        return inst
      end
    end
  end
end
