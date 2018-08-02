require "./chalk/*"
require "option_parser"

module Chalk
  config = Ui::Config.parse!
  exit unless config.validate!

  compiler = Compiler::Compiler.new config
  compiler.run
end
