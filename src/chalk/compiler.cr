require "logger"
require "./constant_folder.cr"
require "./table.cr"

module Chalk
  class Compiler
    def initialize(@config : Config)
      @logger = Logger.new STDOUT
      @lexer = Lexer.new
      @parser = Parser.new
      @logger.debug("Initialized compiler")
      @logger.level = Logger::DEBUG
    end

    private def create_trees(file)
      string = File.read(file)
      tokens = @lexer.lex string
      if tokens.size == 0 && string != ""
        raise "Unable to tokenize file."
      end
      @logger.debug("Finished tokenizing")
      if trees = @parser.parse?(tokens)
        @logger.debug("Finished parsing")
        return trees
      end
      raise "Unable to parse file."
    end

    private def process_initial(trees)
      table = Table.new
      folder = ConstantFolder.new
      trees.each do |tree|
        tree = tree.as(TreeFunction)
        @logger.debug("Constant folding #{tree.name}")
        tree = tree.apply(folder).as(TreeFunction)
        @logger.debug("Storing #{tree.name} in symbol table")
        table[tree.name] = FunctionEntry.new tree
      end
      return table
    end

    private def generate_code(trees, table)
      code = {} of String => Array(Instruction)
      trees.each do |tree|
        tree = tree.as(TreeFunction)
        generator = CodeGenerator.new table, tree
        @logger.debug("Generating code for #{tree.name}")
        instructions = generator.generate!
        code[tree.name] = instructions
      end
      return code
    end

    private def run_tree
      trees = create_trees(@config.file)
      trees.each do |it|
        STDOUT << it
      end
    end

    private def generate_ir
      trees = create_trees(@config.file)
      table = process_initial(trees)
      raise "No main function!" unless table["main"]?
      return { table, generate_code(trees, table) }
    end

    private def run_intermediate
      table, code = generate_ir
      code.each do |name, insts|
        puts "Code for #{name}:"
        insts.each { |it| puts it }
        puts "-----"
      end
    end

    private def generate_binary(instructions)
    end

    private def run_binary
      all_instructions = [] of Instruction
      table, code = generate_ir
      all_instructions.concat code["main"]
      table["main"]?.as(FunctionEntry).addr = 0
      all_instructions << JumpRelativeInstruction.new 0
      code.delete "main"
      code.each do |key, value|
          table[key]?.as(FunctionEntry).addr = all_instructions.size
        all_instructions.concat(value)
        all_instructions << ReturnInstruction.new
      end
      context = InstructionContext.new table, all_instructions.size
      binary = all_instructions.map_with_index { |it, i| it.to_bin(context, i).to_u16 }
      file = File.open("out.ch8", "w")
      binary.each do |inst|
          first = (inst >> 8).to_u8
          file.write_byte(first)
          second = (inst & 0xff).to_u8
          file.write_byte(second)
      end
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
