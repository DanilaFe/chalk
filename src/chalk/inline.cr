module Chalk
  module Builtin
    # Inline function to draw sprite at address I.
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

    # Inline function to await for a key and return it.
    class InlineAwaitKeyFunction < InlineFunction
      def initialize
        @param_count = 0
      end

      def generate!(emitter, params, table, target, free)
        emitter.instructions << Ir::AwaitKeyInstruction.new target
      end
    end

    # Inline function to get font for a given value.
    class InlineGetFontFunction < InlineFunction
      def initialize
        @param_count = 1
      end

      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::GetFontInstruction.new free
      end
    end

    # Inline function to set the delay timer.
    class InlineSetDelayFunction < InlineFunction
      def initialize
        @param_count = 1
      end

      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::SetDelayTimerInstruction.new free
      end
    end

    # Inline function to get the delay timer.
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
