module Chalk
  enum OutputMode
    Tree,
    Intermediate,
    Binary
  end

  class Config
    property file : String
    property mode : OutputMode

    def initialize(@file : String = "",
                   @mode = OutputMode::Tree)
    end

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
