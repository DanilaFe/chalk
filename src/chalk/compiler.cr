require "logger"
require "./constant_folder.cr"
require "./table.cr"

module Chalk
  class Compiler
    def initialize(@config : Config)
      @logger = Logger.new STDOUT
      @logger.debug("Initialized compiler")
      @logger.level = Logger::DEBUG
    end

    private def create_trees(file)
      string = File.read(file)
      @logger.debug("Tokenizing")
      lexer = Lexer.new
      tokens = lexer.lex string
      if tokens.size == 0 && string != ""
        raise "Unable to tokenize file."
      end
      @logger.debug("Finished tokenizing")
      @logger.debug("Beginning parsing")
      parser = Parser.new
      if trees = parser.parse?(tokens)
        @logger.debug("Finished parsing")
        @logger.debug("Beginning constant folding")
        folder = ConstantFolder.new
        trees.map! do |tree|
          @logger.debug("Constant folding #{tree.name}")
          tree.apply(folder).as(TreeFunction)
        end
        @logger.debug("Done constant folding")
        return trees
      end
      raise "Unable to parse file."
    end

    private def create_table(trees)
      table = Table.new
      @logger.debug("Creating symbol table")
      trees.each do |tree|
        @logger.debug("Storing #{tree.name} in symbol table")
        table[tree.name] = FunctionEntry.new tree
      end
      @logger.debug("Done creating symbol table")

      table["draw"] = FunctionEntry.new InlineDrawFunction.new
      table["get_key"] = FunctionEntry.new InlineAwaitKeyFunction.new
      table["get_font"] = FunctionEntry.new InlineGetFontFunction.new
      table["set_delay"] = FunctionEntry.new InlineSetDelayFunction.new
      table["get_delay"] = FunctionEntry.new InlineGetDelayFunction.new
      return table
    end

    private def create_code(tree : TreeFunction, table)
      generator = CodeGenerator.new table, tree
      optimizer = Optimizer.new
      @logger.debug("Generating code for #{tree.name}")
      return optimizer.optimize generator.generate!
    end

    private def create_code(tree : BuiltinFunction, table)
      instructions = [] of Instruction
      tree.generate!(instructions)
      return instructions
    end

    private def create_code(trees : Array(TreeFunction), table)
      code = {} of String => Array(Instruction)
      trees.each do |tree|
        code[tree.name] = create_code(tree, table)
      end
      return code
    end

    private def run_tree
      trees = create_trees(@config.file)
      trees.each do |it|
        STDOUT << it
      end
    end

    private def run_intermediate
      trees = create_trees(@config.file)
      table = create_table(trees)
      code = create_code(trees, table)
      code.each do |name, insts|
        puts "Code for #{name}:"
        insts.each { |it| puts it }
        puts "-----"
      end
    end

    private def generate_binary(table, instructions, dest)
      context = InstructionContext.new table, instructions.size
      binary = instructions.map_with_index { |it, i| it.to_bin(context, i).to_u16 }
      binary.each do |inst|
        first = (inst >> 8).to_u8
        dest.write_byte(first)
        second = (inst & 0xff).to_u8
        dest.write_byte(second)
      end
    end

    private def collect_calls(table)
      open = Set(String).new
      done = Set(String).new

      open << "main"
      while !open.empty?
        first = open.first
        open.delete first

        entry = table[first]?
        raise "Unknown function" unless entry && entry.is_a?(FunctionEntry)
        function = entry.function
        next if function.is_a?(InlineFunction)
        done << first
        next unless function.is_a?(TreeFunction)

        visitor = CallVisitor.new
        function.accept(visitor)
        open.concat(visitor.calls - done)
      end
      return done
    end

    private def run_binary
      all_instructions = [] of Instruction
      trees = create_trees(@config.file)
      table = create_table(trees)
      names = collect_calls(table)
      names.delete "main"

      main_entry = table["main"]?.as(FunctionEntry)
      all_instructions.concat create_code(main_entry.function.as(TreeFunction), table)
      main_entry.addr = 0
      all_instructions << JumpRelativeInstruction.new 0

      names.each do |name|
        entry = table[name]?.as(FunctionEntry)
        entry.addr = all_instructions.size
        function = entry.function
        raise "Trying to compile inlined function" if function.is_a?(InlineFunction)
        all_instructions.concat create_code(function, table)
        all_instructions << ReturnInstruction.new
      end

      file = File.open("out.ch8", "w")
      generate_binary(table, all_instructions, file)
      file.close
    end

    def run
      case @config.mode
      when OutputMode::Tree
        run_tree
      when OutputMode::Intermediate
        run_intermediate
      when OutputMode::Binary
        run_binary
      end
    end
  end
end
