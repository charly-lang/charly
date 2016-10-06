# Interpreter
require "./stack.cr"
require "./interpreter.cr"

# Parsing
require "../syntax/parser/parser.cr"

class InterpreterFascade
  property top : Stack

  def initialize
    @top = Stack.new nil
  end

  def execute_files(files, stack = @top)
    files.map do |file|
      execute_file file, stack
    end
  end

  def execute_file(file, stack = @top)

    # Parsing
    parser = Parser.new file
    parser.parse
    program = parser.tree

    # Execute the file in the interpreter
    unless ARGV.includes? "--noexec"
      stack.file = file
      return Interpreter.new [program], stack
    else
      CharlyTypes::TNull.new
    end
  end
end
