require_relative "Parser.rb"

content = File.open("./input.txt", "r").read
parser = Parser.new

# check if the parser should sanitize
parser.should_sanitize = ARGV.include? '-sanitize'

puts "\n# SYNTAX TREE"
puts parser.parse content
puts "# SYNTAX TREE"

puts "\n# FOUND #{parser.tokens.length} TOKENS"
puts parser.tokens
puts "# TOKENS"
