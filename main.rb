require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "interpreter/Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Prelude
prelude_file = VirtualFile.new "std/prelude.txt"
prelude_program = Parser.parse prelude_file

# Input File
input_file = VirtualFile.new ARGV[0]
input_program = Parser.parse input_file

unless ARGV.include? "--noexec"
  exitValue = Interpreter.new([
    prelude_program,
    input_program
  ]).last_result
  dlog "#{red("Exit:")} #{exitValue}"

  # Return for the program
  if exitValue.is_a? Numeric
    exit exitValue
  else
    exitValue
  end
end
