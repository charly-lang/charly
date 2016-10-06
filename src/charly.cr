require "./charly/file.cr"
require "./charly/interpreter/fascade.cr"

module Charly

  # Read the file from ARGV
  filename = ARGV[0]?

  if filename.is_a? String

    # Create a stack that contains the results of the standard library
    prelude_stack = Stack.new nil
    userfile_stack = Stack.new prelude_stack

    # Get a InterpreterFascade
    interpreter = InterpreterFascade.new

    # Execute the prelude
    unless ARGV.includes? "--noprelude"
      interpreter.execute_file(RealFile.new("./src/charly/std-lib/prelude.charly"), prelude_stack)
    end

    # Execute the userfile
    result = interpreter.execute_file(RealFile.new(filename), userfile_stack)

    # If the --stackdump CLI option was passed
    # display the userstack at the end of execution
    if ARGV.includes? "--stackdump"
      puts userfile_stack
    end

  else
    puts "No filename passed!"
  end
end
