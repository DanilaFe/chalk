require "./chalk/*"
require "option_parser"

module Chalk
  config = Config.parse!
  exit unless config.validate!

  generator = CodeGenerator.new (Table.new)
  compiler = Compiler.new config
  compiler.run
end
