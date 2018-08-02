module Chalk
  module Builtin
    class InlineDrawFunction < InlineFunction
      def initialize
        @param_count = 3
      end

      def generate!(emitter, params, table, target, free)
        if !params[2].is_a?(Trees::TreeLit)
          raise "Third parameter must be a constant."
        end
        emitter.generate! params[0], table, free, free + 1
        emitter.generate! params[1], table, free + 1, free + 2
        emitter.instructions << Ir::DrawInstruction.new free, free + 1, params[2].as(Trees::TreeLit).lit.to_i32
      end
    end

    class InlineAwaitKeyFunction < InlineFunction
      def initialize
        @param_count = 0
      end

      def generate!(emitter, params, table, target, free)
        emitter.instructions << Ir::AwaitKeyInstruction.new target
      end
    end

    class InlineGetFontFunction < InlineFunction
      def initialize
        @param_count = 1
      end

      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::GetFontInstruction.new free
      end
    end

    class InlineSetDelayFunction < InlineFunction
      def initialize
        @param_count = 1
      end

      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::SetDelayTimerInstruction.new free
      end
    end

    class InlineGetDelayFunction < InlineFunction
      def initialize
        @param_count = 0
      end

      def generate!(emitter, params, table, target, free)
        emitter.instructions << Ir::GetDelayTimerInstruction.new target
      end
    end
  end
end
