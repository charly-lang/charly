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
  files.unshift "std/prelude.charly"
end

programs = []
files.each do |file|
  file = VirtualFile.new file
  programs << Parser.parse(file)
end

unless ARGV.include? "--noexec"
  exitValue = Interpreter.new(programs).last_result
  if !exitValue.kind_of?(Numeric)
    exitValue = 0
  end
  dlog "#{red("Exit:")} #{exitValue}"

  exit exitValue
end
