require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "syntax/Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Create a new file for the input file
dlog "Reading source file"
input_file = VirtualFile.new_from_path ARGV[0]

if ARGV.include? '--fdump'
  puts "--- #{filename} ---"
  puts input_file.content
  puts "------"
end

# Create the parser
dlog "Instantiating Parser"
parser = Parser.new
parser.output_intermediate_tree = ARGV.include? '--intermediate'

# Parse the program
program = parser.parse input_file.content

if ARGV.include? '--ast'
  puts "--- abstract syntax tree ---"
  puts parser.tree
  puts "------"
end

if ARGV.include? '--tokens'
  puts "--- #{parser.tokens.length} tokens ---"
  puts parser.tokens
  puts "------"
end

dlog "Instantiating Interpreter"
interpreter = Interpreter.new([
  # parser.parse(File.open("testing/prelude.txt", "r").read),
  program
])
interpreter.execute
