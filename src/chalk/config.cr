module Chalk
  module Ui
    # The mode in which the compiler operates.
    # Defines what actions are and aren't performed.
    enum OutputMode
      # The text is only parsed, and the result is printed to the screen.
      Tree,
      # The text is parsed and converted to intermediate representation.
      # The intermediate representation is then printed to the screen.
      Intermediate,
      # The text is converted into a full CHIP-8 executable.
      Binary
    end

    # A configuration class created from the command-line parameters.
    class Config
      # Gets the file to be compiled.
      getter file : String
      # Sets the file to be compiled.
      setter file : String
      # Gets the mode in which the compiler should operate.
      getter mode : OutputMode
      # Sets the mode in which the compiler should operate.
      setter mode : OutputMode

      # Creates a new configuration.
      def initialize(@file = "",
                     @mode = OutputMode::Tree)
      end

      # Reads a configuration from the command line options.
      def self.parse!
        config = self.new
        OptionParser.parse! do |parser|
          parser.banner = "Usage: chalk [arguments]"
          parser.on("-m", "--mode=MODE", "Set the mode of the compiler.") do |mode|
            case mode.downcase
            when "tree", "t"
              config.mode = OutputMode::Tree
            when "intermediate", "i"
              config.mode = OutputMode::Intermediate
            when "binary", "b"
              config.mode = OutputMode::Binary
            else
              puts "Invalid mode type. Using default."
            end
          end
          parser.on("-f", "--file=FILE", "Set the input file to compile.") do |file|
            config.file = file
          end
          parser.on("-h", "--help", "Show this message.") { puts parser }
        end
        return config
      end

      # Validates the options provided, returning true if
      # they are valid and false otherwise.
      def validate!
        if file == ""
          puts "No source file specified."
          return false
        elsif !File.exists? file
          puts "Unable to open source file."
          return false
        end
        return true
      end
    end
  end
end
