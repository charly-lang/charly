require "./charly/file.cr"
require "./charly/interpreter/fascade.cr"

module Charly

  # Read the file from ARGV
  filename = ARGV[0]?

  if filename.is_a? String

    # Collection of all top-level files that will be executed
    files = [] of RealFile

    # Create a new virtualfile for the input
    files << RealFile.new filename

    # Unless the prelude is disabled, include it too
    unless ARGV.includes? "--noprelude"

      # TODO: Figure out how to find the std-library at runtime
      files.unshift RealFile.new "./src/charly/std-lib/prelude.charly"
    end

    # Execute the file using the fascade
    interpreter = InterpreterFascade.new
    result = interpreter.execute_files(files)

    puts interpreter.top

  else
    puts "No filename passed!"
  end
end
