module Chalk
  class Entry
  end

  class FunctionEntry < Entry
    property function : TreeFunction | BuiltinFunction | InlineFunction
    property addr : Int32

    def initialize(@function, @addr = -1)
    end

    def to_s(io)
      io << "[function]"
    end
  end

  class VarEntry < Entry
    property register : Int32

    def initialize(@register)
    end

    def to_s(io)
      io << "[variable] " << "(R" << @register.to_s(16) << ")"
    end
  end

  class Table
    property parent : Table?

    def initialize(@parent = nil)
      @data = {} of String => Entry
    end

    def []?(key)
      if entry = @data[key]?
        return entry
      end
      return @parent.try &.[key]?
    end

    def []=(key, entry)
      @data[key] = entry
    end

    def to_s(io)
      @parent.try &.to_s(io)
      io << @data.map { |k, v| k + ": " + v.to_s }.join("\n")
    end
  end
end
