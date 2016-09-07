require_relative "AST.rb"
require_relative "Helper.rb"

# Runs a given program
class Interpreter

  # Initialize the interpreter and insert all required programs
  def initialize(programs)
    @programs = programs
    @symbols = {}
  end

  # Run all programs starting with the first one in the array
  def execute
    last_result = NIL
    @programs.each do |program|
      last_result = run_program program
    end
    last_result
  end

  # Executes a single program
  def run_program(program)

    # The first node in the tree is always a block
    run_block program.children[0]
  end

  # Runs all expressions inside a given block
  def run_block(block)

    # A block contains a list of expressions
    # execute all of them
    last_result = NIL
    block.children.each do |expression|
      last_result = run_expression expression
    end
    last_result
  end

  # Executes a single expression and returns it's value
  def run_expression(expression)

    # Different types of expressions
    #
    # - VariableAssignment
    # - BinaryExpression
    # - CallExpression
    case expression
    when VariableAssignment
      value = run_expression expression.expression
      @symbols[expression.identifier.value] = value
      return value
    when BinaryExpression
      lhs = run_expression expression.left
      rhs = run_expression expression.right

      case expression.operator.value
      when "+"
        return lhs + rhs
      when "-"
        return lhs - rhs
      when "*"
        return lhs * rhs
      when "/"
        return lhs / rhs
      end
    when CallExpression
      arguments = []
      expression.argumentlist.children.each do |arg|
        arguments << run_expression(arg)
      end
      return call_internal_function(expression.identifier.value, arguments)
    when IdentifierLiteral
      return @symbols[expression.value]
    when NumericLiteral
      return expression.value
    end
  end

  # Execute a given internal function
  def call_internal_function(name, arguments)
    case name
    when "print"
      arguments.each do |arg|
        puts arg
      end
      return NIL
    end
  end
end
