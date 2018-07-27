require "./chalk/*"
require "option_parser"

module Chalk
  config = Config.parse!
  exit unless config.validate!

  compiler = Compiler.new config
  compiler.run
end
