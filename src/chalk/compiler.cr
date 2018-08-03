require "logger"
require "./constant_folder.cr"
require "./table.cr"

module Chalk
  module Compiler
    # Top-level class to tie together the various
    # components, such as the `Lexer`,
    # `ParserCombinators::Parser`, and `Optimizer`
    class Compiler
      # Creates a new compiler with the given *config*.
      def initialize(@config : Ui::Config)
        @logger = Logger.new STDOUT
        @logger.debug("Initialized compiler")
        @logger.level = Logger::DEBUG
      end

      # Reads a file an extracts instances of
      # `Trees:TreeFunction`.
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
        parser = ParserCombinators::Parser.new
        if trees = parser.parse?(tokens)
          @logger.debug("Finished parsing")
          @logger.debug("Beginning constant folding")
          folder = Trees::ConstantFolder.new
          trees.map! do |tree|
            @logger.debug("Constant folding #{tree.name}")
            tree.apply(folder).as(Trees::TreeFunction)
          end
          @logger.debug("Done constant folding")
          return trees
        end
        raise "Unable to parse file."
      end

      # Creates a default symbol table using the default functions,
      # as well as the functions declared by *trees*
      private def create_table(trees)
        table = Table.new
        @logger.debug("Creating symbol table")
        trees.each do |tree|
          @logger.debug("Storing #{tree.name} in symbol table")
          table[tree.name] = FunctionEntry.new tree
        end
        @logger.debug("Done creating symbol table")

        table["draw"] = FunctionEntry.new Builtin::InlineDrawFunction.new
        table["get_key"] = FunctionEntry.new Builtin::InlineAwaitKeyFunction.new
        table["get_font"] = FunctionEntry.new Builtin::InlineGetFontFunction.new
        table["set_delay"] = FunctionEntry.new Builtin::InlineSetDelayFunction.new
        table["get_delay"] = FunctionEntry.new Builtin::InlineGetDelayFunction.new
        return table
      end

      # Generates and optimizes intermediate representation for the given *tree*,
      # looking up identifiers in the symbol *table*, and appending the given *instruction*
      # at the end of the function to ensure correct program flow.
      private def create_code(tree : Trees::TreeFunction, table, instruction = Ir::ReturnInstruction.new)
        tree.reduce(Trees::TypeChecker.new table, tree.type.return_type)
        optimizer = Optimizer.new
        generator = CodeGenerator.new table, tree
        @logger.debug("Generating code for #{tree.name}")
        code = generator.generate!
        code << instruction
        return optimizer.optimize(code)
      end

      # Generate code for a builtin function. Neither the *table* nor the *instruction*
      # are used, and serve to allow function overloading.
      private def create_code(function : Builtin::BuiltinFunction, table, instruction = nil)
        instructions = [] of Ir::Instruction
        function.generate!(instructions)
        return instructions
      end

      # Creates a hash containing function names and their generated code.
      # Only functions parsed from the file are compiled, and the *table*
      # is used for looking up identifiers.
      private def create_code(trees : Array(Trees::TreeFunction), table)
        code = {} of String => Array(Ir::Instruction)
        trees.each do |tree|
          code[tree.name] = create_code(tree, table)
        end
        return code
      end

      # Runs in the tree `Ui::OutputMode`. The file is
      # tokenized and parsed, and the result is printed
      # to the standard output.
      private def run_tree
        trees = create_trees(@config.file)
        trees.each do |it|
          STDOUT << it
        end
      end

      # Runs in the intermediate `Ui::OutputMode`. The file
      # is tokenized and parsed, and for each function,
      # intermediate representation is generated. However,
      # an executable is not generated, and the IR
      # is printed to the screen.
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

      # Creates binary from the given *instructions*,
      # using the symbol *table* for lookups, and writes
      # the output to *dest*
      private def generate_binary(table, instructions, dest)
        binary = instructions.map_with_index { |it, i| it.to_bin(table, instructions.size, i).to_u16 }
        binary.each do |inst|
          first = (inst >> 8).to_u8
          dest.write_byte(first)
          second = (inst & 0xff).to_u8
          dest.write_byte(second)
        end
      end

      # Find all calls performed by the functions
      # stored in the *table*, starting at the main function.
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
          next if function.is_a?(Builtin::InlineFunction)
          done << first
          next unless function.is_a?(Trees::TreeFunction)

          visitor = Trees::CallVisitor.new
          function.accept(visitor)
          open.concat(visitor.calls - done)
        end
        return done
      end

      # Runs in the binary `Ui::OutputMode`. The file is
      # converted into an executable.
      private def run_binary
        all_instructions = [] of Ir::Instruction
        trees = create_trees(@config.file)
        table = create_table(trees)
        names = collect_calls(table)
        names.delete "main"

        main_entry = table["main"]?.as(FunctionEntry)
        all_instructions.concat create_code(main_entry.function.as(Trees::TreeFunction),
          table, Ir::JumpRelativeInstruction.new 0)
        main_entry.addr = 0

        names.each do |name|
          entry = table[name]?.as(FunctionEntry)
          entry.addr = all_instructions.size
          function = entry.function
          raise "Trying to compile inlined function" if function.is_a?(Builtin::InlineFunction)
          all_instructions.concat create_code(function, table)
          all_instructions << Ir::ReturnInstruction.new
        end

        file = File.open("out.ch8", "w")
        generate_binary(table, all_instructions, file)
        file.close
      end

      # Runs the compiler.
      def run
        case @config.mode
        when Ui::OutputMode::Tree
          run_tree
        when Ui::OutputMode::Intermediate
          run_intermediate
        when Ui::OutputMode::Binary
          run_binary
        end
      end
    end
  end
end
