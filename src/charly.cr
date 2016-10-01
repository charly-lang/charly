require "./charly/file.cr"
require "./charly/syntax/lexer/lexer.cr"

module Charly

  # Read the file from ARGV
  filename = ARGV[0]?

  if filename.is_a? String

    # Create a new virtualfile
    input = RealFile.new filename

    # Create a new lexer
    lexer = Lexer.new input
    tokens = lexer.all_tokens

    tokens.each do |token|
      puts token
    end
  else
    puts "No filename passed!"
  end
end
