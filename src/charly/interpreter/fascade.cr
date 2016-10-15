# Interpreter
require "./stack/stack.cr"
require "./interpreter.cr"
require "./session.cr"

# Parsing
require "../syntax/parser/parser.cr"

class InterpreterFascade
  property top : Stack
  property session : Session

  def initialize(@session)
    @top = Stack.new nil
  end

  def execute_file(file, stack = @top)

    # Parsing
    parser = Parser.new file, @session
    parser.parse
    program = parser.tree

    # Setup the stack
    stack.file = file
    stack.session = @session

    # Execute the file in the interpreter
    unless @session.flags.includes? "noexec"
      Interpreter.new([program], stack).program_result
    else
      CharlyTypes::TNull.new
    end
  end
end
