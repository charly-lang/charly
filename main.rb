$debug = ARGV.include? '--log'
require_relative "Helper.rb"
dlog "Starting up!"

dlog "Loading Parser"
require_relative "Parser.rb"

dlog "Loading Interpreter"
require_relative "Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Read the contents of the file
dlog "Reading contents of source file"
filename = ARGV[0]
content = File.open(filename, "r").read

if ARGV.include? '--fdump'
  puts "--- #{filename} ---"
  puts content
  puts "------"
end

# Create the parser
dlog "Instantiating Parser"
parser = Parser.new
parser.output_intermediate_tree = ARGV.include? '--intermediate'

# Parse the program
program = parser.parse content

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
