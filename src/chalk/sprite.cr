module Chalk
  module Table
    class Sprite
      def initialize
        @pixels = Hash(UInt8, UInt8).new(default_value: 0_u8)
      end

      def initialize(string, blank_char = ' ')
        @pixels = Hash(UInt8, UInt8).new(default_value: 0_u8)
        string.split("\n").each_with_index do |s, i|
          break if i > 15
          index = 0
          byte = 0_u8
          s.each_char do |char|
            break if index > 7
            bit = (char == blank_char) ? 0_u8 : 1_u8
            byte |= (bit << (7 - index))
            index += 1
          end
          @pixels[i.to_u8] = byte
        end
      end

      def set_pixel(x, y)
        raise "Invalid x-coordinate" if x > 7
        raise "Invalid y-coordinate" if y > 15
        x = x.to_u8
        y = y.to_u8
        char = @pixels.fetch y, 0_u8
        char |= (1 << (7 - x))
        @pixels[y] = char
      end

      def unset_pixel(x, y)
        raise "Invalid x-coordinate" if x > 7
        raise "Invalid y-coordinate" if y > 15
        x = x.to_u8
        y = y.to_u8
        char = @pixels.fetch y, 0_u8
        char &= ~(1 << (7 - x))
        @pixels[y] = char
      end

      def toggle_pixel(x, y)
        raise "Invalid x-coordinate" if x > 7
        raise "Invalid y-coordinate" if y > 15
        x = x.to_u8
        y = y.to_u8
        char = @pixels.fetch y, 0_u8
        char ^= (1 << (7 - x))
        @pixels[y] = char
      end

      def draw(io = STDOUT, blank_char = ' ', ink_char = 'x')
        until_y = @pixels.keys.max?
        return unless until_y
        (0..until_y).each do |y|
          row = @pixels.fetch y, 0_u8
          pointer = 0b10000000
          while pointer != 0
            draw_pixel = (row & pointer) != 0
            io << (draw_pixel ? ink_char : blank_char)
            pointer = pointer >> 1
          end
          io << '\n'
        end
      end

      def encode
        if until_y = @pixels.keys.max?
          return (0..until_y).map { |it| @pixels.fetch it, 0_u8 }
        end
        return [0_u8]
      end
    end
  end
end
