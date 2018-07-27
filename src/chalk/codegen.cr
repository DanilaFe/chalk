require "./ir.cr"

module Chalk
  class CodeGenerator
    def initialize(@table : Table)
      @register = 0
      @instructions = [] of Instruction
      @block_edges = [] of Int32
    end

    private def load(into, value)
      @instructions << LoadInstruction.new into, value.to_i32
    end

    private def loadr(into, from)
      @instructions << LoadRegInstruction.new into, from
    end

    private def op(op, into, from)
      @instructions << OpRegInstruction.new op, into, from
    end

    private def store(up_to)
      @instructions << StoreInstruction.new up_to
    end

    private def restore(up_to)
      @instructions << RestoreInstruction.new up_to
    end

    private def ret(reg)
      @instructions << ReturnInstruction.new reg
    end

    def generate(tree : Tree, target : Int32)
      case tree
      when TreeId
        entry = @table[tree.id]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        loadr target, entry.as(VarEntry).register
      when TreeLit
        load target, tree.lit
      when TreeOp
        generate tree.left, target
        generate tree.right, @register
        op tree.op, target, @register
      when TreeBlock
        tree.children.each do |child|
          generate child, @register
        end
      when TreeVar
        entry = @table[tree.name]?
        if entry == nil
          entry = VarEntry.new @register
          @register += 1
          @table[tree.name] = entry
        end
        raise "Unknown variable" unless entry.is_a?(VarEntry)
        generate tree.expr, entry.register
      when TreeAssign
        entry = @table[tree.name]?
        raise "Unknown variable" unless entry &&
                                        entry.is_a?(VarEntry)
        generate tree.expr, entry.as(VarEntry).register
      when TreeReturn
        generate tree.rvalue, target
        ret target
      end
    end

    def generate(tree : Tree)
      generate(tree, 0)
      @block_edges << @instructions.size
      @block_edges.sort!
      return @instructions
    end
  end
end
