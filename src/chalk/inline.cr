require "./builtin"
require "./type"

module Chalk
  module Builtin
    # Inline function to await for a key and return it.
    class InlineAwaitKeyFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        emitter.instructions << Ir::AwaitKeyInstruction.new target
      end
      def type
          return Compiler::FunctionType.new(([] of Compiler::Type), Compiler::Type::U8)
      end
    end

    # Inline function to set the delay timer.
    class InlineSetDelayFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::SetDelayTimerInstruction.new free
      end

      def type
          return Compiler::FunctionType.new([Compiler::Type::U8], Compiler::Type::U0)
      end
    end

    # Inline function to get the delay timer.
    class InlineGetDelayFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        emitter.instructions << Ir::GetDelayTimerInstruction.new target
      end
      def type
          return Compiler::FunctionType.new(([] of Compiler::Type), Compiler::Type::U8)
      end
    end

    # Function to set the sound timer.
    class InlineSetSoundFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::SetSoundTimerInstruction.new free
      end

      def type
          return Compiler::FunctionType.new([Compiler::Type::U8], Compiler::Type::U0)
      end
    end

    # Function to draw numbers.
    class InlineDrawNumberFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        emitter.to_stack
        # Save variables from R0-R2
        emitter.store 0x2
        emitter.load free, 0x3
        emitter.addi free
        # Write BCD values to I
        emitter.generate! params[0], table, free, free + 1
        emitter.instructions << Ir::BCDInstruction.new free
        emitter.restore 0x2
        # Get the coordinates
        free = 3 if free < 3
        emitter.generate! params[1], table, free, free + 1
        emitter.generate! params[2], table, free + 1, free + 2
        # Draw
        emitter.instructions << Ir::GetFontInstruction.new 0x0
        emitter.instructions << Ir::DrawInstruction.new free, free + 1, 5
        emitter.op(Compiler::TokenType::OpAdd, free, 6)
        emitter.instructions << Ir::GetFontInstruction.new 0x1
        emitter.instructions << Ir::DrawInstruction.new free, free + 1, 5
        emitter.op(Compiler::TokenType::OpAdd, free, 6)
        emitter.instructions << Ir::GetFontInstruction.new 0x2
        emitter.instructions << Ir::DrawInstruction.new free, free + 1, 5
        # Load variables from RO-R2 back
        emitter.to_stack
        emitter.restore 0x2
      end

      def type
          return Compiler::FunctionType.new([Compiler::Type::U8] * 3, Compiler::Type::U0)
      end
    end

    class InlineDrawSpriteFunction < InlineFunction
      def generate!(emitter, params, table, target, free)
        raise "First parameter should be a sprite name." if !params[0].is_a?(Trees::TreeId)
        sprite_name = params[0].as(Trees::TreeId).id
        sprite = table.get_sprite?(sprite_name).not_nil!.sprite
        emitter.generate! params[1], table, free, free + 1
        emitter.generate! params[2], table, free + 1, free + 2
        emitter.instructions << Ir::SetISpriteInstruction.new params[0].as(Trees::TreeId).id
        emitter.instructions << Ir::DrawInstruction.new free, free + 1, sprite.height.to_i32
      end

      def type
          return Compiler::FunctionType.new([Compiler::Type::U8] * 3, Compiler::Type::U0)
      end
    end
  end
end
