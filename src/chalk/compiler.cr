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

    private def run_intermediate
      trees = create_trees(@config.file)
      table = process_initial(trees)
      raise "No main function!" unless table["main"]?
      code = generate_code(trees, table)
      code.each do |name, insts|
        puts "Code for #{name}:"
        insts.each { |it| puts it }
        puts "-----"
      end
    end

    private def run_binary
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
