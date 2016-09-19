require_relative "misc/Helper.rb"
require_relative "interpreter/fascade.rb"

# Check if a filename was passed
if ARGV.length == 0
  raise "No filename passed!"
end

# Collect the files we want to execute
files = [ARGV[0]]
unless ARGV.include? "--noprelude"
  files.unshift "std/prelude.charly"
end

# Execute the program
exit_value = InterpreterFascade.execute_files(files);

# If the exit_value of the program is a Types::NumericType
# use that value as the return value of the program
if exit_value.is_a? Types::NumericType
  exit_value = exit_value.value
else
  exit_value = 0
end

# Exit
exit exit_value
