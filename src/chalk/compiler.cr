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
        @logger.level = @config.loglevel
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
            next tree unless tree.is_a?(Trees::TreeFunction)
            @logger.debug("Constant folding #{tree.name}")
            tree.apply(folder)
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
          case tree
          when Trees::TreeSprite
              @logger.debug("Storing sprite #{tree.name} in symbol table")
              table.set_sprite tree.name, SpriteEntry.new tree.sprite
          when Trees::TreeFunction
              @logger.debug("Storing function #{tree.name} in symbol table")
              table.set_function tree.name, FunctionEntry.new tree
          else
              @logger.debug("Unexpected tree type in input.")
          end
        end
        @logger.debug("Done creating symbol table")

        table.set_function "get_key", FunctionEntry.new Builtin::InlineAwaitKeyFunction.new
        table.set_function "set_delay", FunctionEntry.new Builtin::InlineSetDelayFunction.new
        table.set_function "get_delay", FunctionEntry.new Builtin::InlineGetDelayFunction.new
        table.set_function "set_sound", FunctionEntry.new Builtin::InlineSetSoundFunction.new
        table.set_function "draw_number", FunctionEntry.new Builtin::InlineDrawNumberFunction.new
        table.set_function "draw_sprite", FunctionEntry.new Builtin::InlineDrawSpriteFunction.new
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
        return code # optimizer.optimize(code)
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

      private def create_code(trees : Array(Trees::Tree), table)
        functions = trees.select &.is_a?(Trees::TreeFunction)
        return create_code(functions.map &.as(Trees::TreeFunction), table)
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
          dest << first
          second = (inst & 0xff).to_u8
          dest << second
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

          entry = table.get_function? first
          raise "Unknown function" unless entry
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

        main_entry = table.get_function?("main").not_nil!
        all_instructions.concat create_code(main_entry.function.as(Trees::TreeFunction),
          table, Ir::JumpRelativeInstruction.new 0)
        main_entry.addr = 0

        names.each do |name|
          entry = table.get_function?(name).not_nil!
          entry.addr = all_instructions.size
          function = entry.function
          raise "Trying to compile inlined function" if function.is_a?(Builtin::InlineFunction)
          all_instructions.concat create_code(function, table)
          all_instructions << Ir::ReturnInstruction.new
        end

        sprite_bytes = [] of UInt8
        offset = 0
        table.sprites.each do |k, v|
          data = v.sprite.encode
          v.addr = offset + all_instructions.size * 2
          offset += data.size
          sprite_bytes.concat data
        end

        binary = [] of UInt8
        file = File.open(@config.output, "w")
        generate_binary(table, all_instructions, binary)
        binary.concat sprite_bytes
        binary.each do |byte|
          file.write_byte byte
        end
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
