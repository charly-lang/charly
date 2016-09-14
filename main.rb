require_relative "misc/Helper.rb"
require_relative "misc/File.rb"
require_relative "syntax/Parser.rb"
require_relative "interpreter/Interpreter.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

files = [ARGV[0]]
unless ARGV.include? "--noprelude"
  files.unshift "std/prelude.txt"
end

programs = []
files.each do |file|
  file = VirtualFile.new file
  programs << Parser.parse(file)
end

unless ARGV.include? "--noexec"
  exitValue = Interpreter.new(programs).last_result
  dlog "#{red("Exit:")} #{exitValue}"

  # Return for the program
  if exitValue.is_a? Numeric
    exit exitValue
  else
    exitValue
  end
end
