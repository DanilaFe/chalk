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
      # Gets the log level
      getter loglevel : Logger::Severity
      # Sets the log level
      setter loglevel : Logger::Severity

      # Creates a new configuration.
      def initialize(@file = "",
                     @mode = OutputMode::Tree,
                     @loglevel = Logger::Severity::DEBUG)
      end

      # Reads a configuration from the command line options.
      def self.parse!
        config = self.new
        OptionParser.parse! do |parser|
          parser.banner = "Usage: chalk [arguments]"
          parser.on("-m", "--mode=MODE", "Set the mode of the compiler.") do |mode|
            hash = { 
                "tree" => OutputMode::Tree,
                "t" => OutputMode::Tree,
                "intermediate" => OutputMode::Intermediate,
                "i" => OutputMode::Intermediate,
                "binary" => OutputMode::Binary,
                "b" => OutputMode::Binary
            }
            puts "Invalid mode type. Using default." if !hash.has_key?(mode)
            config.mode = hash[mode]? || OutputMode::Tree
          end
          parser.on("-f", "--file=FILE", "Set the input file to compile.") do |file|
            config.file = file
          end
          parser.on("-l", "--log=LOG", "Set the log level of the compiler.") do |log|
            hash = {
                "debug" => Logger::Severity::DEBUG,
                "fatal" => Logger::Severity::FATAL,
                "error" => Logger::Severity::ERROR,
                "info" => Logger::Severity::INFO,
                "unknown" => Logger::Severity::UNKNOWN,
                "warn" => Logger::Severity::WARN
            }
            puts "Invalid log level. Using default." if !hash.has_key?(log)
            config.loglevel = hash[log]? || Logger::Severity::DEBUG
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
