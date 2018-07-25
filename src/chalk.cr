require "./chalk/*"

module Chalk
  lexer = Lexer.new
  parser = Parser.new

  tokens = lexer.lex(File.read("test.txt"))
  trees = parser.parse?(tokens)
  trees.try do |trees|
      trees.each { |tree| puts tree }
  end
end
