require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Create a new file for the input file
# parse the program afterwards
begin
  input_file = VirtualFile.new ARGV[0]
  input_program = Parser.parse input_file
rescue Exception => e
  dlog red("Parse Failure: #{e.message}")
  exit 1
end

# Show the generated abstract syntax tree if the needed cli flag is passed
if ARGV.include? '--ast'
  puts "--- abstract syntax tree ---"
  puts input_program.tree
  puts "------"
end

dlog "Instantiating Interpreter"
interpreter = Interpreter.new([
  input_program
])
interpreter.execute
