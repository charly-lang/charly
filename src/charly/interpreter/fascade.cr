# Interpreter
require "./stack.cr"
require "./interpreter.cr"
require "./session.cr"

# Parsing
require "../syntax/parser/parser.cr"

class InterpreterFascade
  property top : Stack
  property session : Session?
  property flags : Array(String)

  def initialize(session = nil, flags = [] of String)
    @session = session
    @top = Stack.new nil
    @flags = flags
  end

  def execute_files(files, stack = @top)
    files.map do |file|
      execute_file file, stack
    end
  end

  def execute_file(file, stack = @top)

    # Parsing
    parser = Parser.new file, @flags
    parser.parse
    program = parser.tree

    # Execute the file in the interpreter
    unless @flags.includes? "noexec"
      stack.file = file
      stack.session = @session
      return Interpreter.new [program], stack, @flags
    else
      CharlyTypes::TNull.new
    end
  end
end
