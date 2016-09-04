require_relative "Parser.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Read the contents of the file
content = File.open(ARGV[0], "r").read

# Create the parser
parser = Parser.new
$debug = ARGV.include? '--log'

program = parser.parse content

if ARGV.include? '--ast'
  puts "------"
  puts parser.tree
end

if ARGV.include? '--tokens'
  puts "--- #{parser.tokens.length} TOKENS ---"
  puts parser.tokens
end

