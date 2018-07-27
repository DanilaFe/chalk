module Chalk
  class Entry
  end

  class FunctionEntry < Entry
    property function : TreeFunction
    property addr : Int32

    def initialize(@function : TreeFunction, @addr : Int32 = -1)
    end

    def to_s(io)
      io << "[function]"
    end
  end

  class VarEntry < Entry
    property register : Int32

    def initialize(@register : Int32)
    end

    def to_s(io)
      io << "[variable] " << "(R" << @register.to_s(16) << ")"
    end
  end

  class Table
    property parent : Table?

    def initialize(@parent : Table? = nil)
      @data = {} of String => Entry
    end

    def []?(key) : Entry?
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
