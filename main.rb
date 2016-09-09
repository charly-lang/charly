require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Prelude
prelude_file = VirtualFile.new "testing/prelude.txt"
prelude_program = Parser.parse prelude_file

# Input File
input_file = VirtualFile.new ARGV[0]
input_program = Parser.parse input_file

unless ARGV.include? "--noexec"
  interpreter = Interpreter.new([
    prelude_program,
    input_program
  ])
  exitValue = interpreter.execute
  dlog "#{red("Exit:")} #{exitValue}"
end
