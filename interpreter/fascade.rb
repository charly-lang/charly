require_relative "../misc/Helper.rb"
require_relative "../misc/File.rb"
require_relative "../syntax/Parser.rb"
require_relative "Interpreter.rb"

class InterpreterFascade

  # Execute a couple of files
  # optionally passing a stack that will be used as the global stack
  def self.execute_files(files, stack = nil)

    # No stack was passed
    if stack == nil
      stack = Stack.new NIL
    end

    files.each do |file|
      self.execute_file file, stack
    end
  end

  # Execute a single file
  # optionally passing a stack that will be used as the global stack
  def self.execute_file(file, stack = nil)
    file = VirtualFile.new file
    program = Parser.parse(file)

    unless ARGV.include? "--noexec"

      # Execute the program
      interpreter = Interpreter.new([program], stack)
      exit_value = interpreter.last_result

      # Logging and script exit
      dlog "#{yellow(file.filename)} exited with: #{exit_value.method(:to_s).super_method.call}"
      return exit_value
    end
    return Types::NullType.new
  end
end
