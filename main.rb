require_relative "Parser.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Read the contents of the file
content = File.open(ARGV[0], "r").read

# Create the parser
parser = Parser.new

puts "\n# SYNTAX TREE"
puts parser.parse content
puts "# SYNTAX TREE"

puts "\n# FOUND #{parser.tokens.length} TOKENS"
puts parser.tokens
puts "# TOKENS"
