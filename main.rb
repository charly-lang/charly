require_relative "Parser.rb"
require_relative "Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Read the contents of the file
filename = ARGV[0]
content = File.open(filename, "r").read

if ARGV.include? '--fdump'
  puts "------"
  puts content
end

# Create the parser
parser = Parser.new filename
parser.output_intermediate_tree = ARGV.include? '--intermediate'
$debug = ARGV.include? '--log'
if $debug
  puts "------"
end

program = parser.parse content

interpreter = Interpreter.new([
  program
])
puts "=> #{interpreter.execute}"

if ARGV.include? '--ast'
  puts "------"
  puts parser.tree
end

if ARGV.include? '--tokens'
  puts "--- #{parser.tokens.length} TOKENS ---"
  puts parser.tokens
end
