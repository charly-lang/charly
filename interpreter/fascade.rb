require_relative "../misc/Helper.rb"
require_relative "../misc/File.rb"
require_relative "../syntax/Parser.rb"
require_relative "Interpreter.rb"
require_relative "session.rb"

class InterpreterFascade

  # Execute a couple of strings
  # *scripts* is an array of strings
  def self.execute_eval(scripts, stack = nil)
    self.execute_virtual_files(scripts.map { |file|
      EvalFile.new file
    }, stack)
  end

  # Execute a couple of files
  # *files* is an array of filenames
  def self.execute_files(files, stack = nil)
    self.execute_virtual_files(files.map { |file|
      RealFile.new file
    }, stack)
  end

  # Execute a couple of VirtualFiles
  # optionally passing a stack that will be used as the global stack
  def self.execute_virtual_files(files, stack = nil)

    # Optionally create a new stack for the files
    if stack == nil
      stack = Stack.new nil
      stack.session = Session.new
    end

    last_result = Types::NullType.new
    files.each do |file|
      last_result = self.execute_virtual_file(file, stack)
    end
    last_result
  end

  # Execute a VirtualFile
  # optionally passing a stack that will be used as the global stack
  def self.execute_virtual_file(file, stack = nil)

    # Add the file to the current sessions
    # active files
    stack.session.files << file

    # Parse the program
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
