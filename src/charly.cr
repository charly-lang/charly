require "./charly/file.cr"
require "./charly/syntax/parser/parser.cr"

module Charly

  # Read the file from ARGV
  filename = ARGV[0]?

  if filename.is_a? String

    # Create a new virtualfile
    input = RealFile.new filename

    # Parse the file
    parser = Parser.new input
    program = parser.parse

    puts program
  else
    puts "No filename passed!"
  end
end
