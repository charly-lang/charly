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
  input_file = VirtualFile.new ARGV[0]
  input_program = Parser.parse input_file
begin
rescue Exception => e
  dlog red("Parse Failure: #{e.message}")
  exit 1
end

unless ARGV.include? "--noexec"
  interpreter = Interpreter.new([
    input_program
  ])
  exitValue = interpreter.execute
  dlog "#{red("Exit:")} #{exitValue}"
end
