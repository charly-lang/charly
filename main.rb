require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Create a new file for the input file
input_file = VirtualFile.new ARGV[0]

if ARGV.include? '--fdump'
  puts "--- #{filename} ---"
  puts input_file
  puts "------"
end

# Parse the program
input_program = Parser.parse input_file

if ARGV.include? '--ast'
  puts "--- abstract syntax tree ---"
  puts input_program.tree
  puts "------"
end

if ARGV.include? '--tokens'
  puts "--- #{input_program.tokens.length} tokens ---"
  puts input_program.tokens
  puts "------"
end

dlog "Instantiating Interpreter"
interpreter = Interpreter.new([
  input_program
])
interpreter.execute
