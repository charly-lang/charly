require_relative "syntax/AST.rb"
require_relative "misc/Helper.rb"

# Runs a given program
class Interpreter
  attr_reader :symbols

  # Initialize the interpreter and insert all required programs
  def initialize(programs)
    @programs = programs
    @symbols = {}
  end

  # Run all programs starting with the first one in the array
  def execute
    last_result = NIL
    @programs.each do |program|
      dlog "Executing program"
      last_result = run_program program
    end
    last_result
  end

  # Executes a single program
  def run_program(program)

    # Check if the program contains a block
    if program.children.length == 1

      # The first node in the tree is always a block
      return run_block program.children[0]
    end

    NIL
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
  def run_expression(node)

    # VariableInitialisation
    if node.is(VariableInitialisation)
      value = run_expression node.expression
      @symbols[node.identifier.value] = value
      return value
    end

    # VariableDeclaration
    if node.is(VariableDeclaration)
      @symbols[node.identifier.value] = NIL
    end

    # BinaryExpression
    if node.is(BinaryExpression)
      left = run_expression node.left
      right = run_expression node.right

      case node.operator
      when PlusOperator
        return left + right
      when MinusOperator
        return left - right
      when MultOperator
        return left * right
      when DivdOperator
        return left / right
      when ModOperator
        return left % right
      when PowOperator
        return left ** right
      end
    end

    # Call Expressions
    if node.is(CallExpression)

      # Resolve all arguments first
      arguments = []
      node.argumentlist.each do |argument|
        arguments << run_expression(argument)
      end

      call_internal_function node.identifier.value, arguments
    end

    # Nested expressions inside a statement
    if node.is(Statement) && node.children.length == 1
      if node.children[0].is(Expression, NumericLiteral, StringLiteral, IdentifierLiteral)
        return run_expression node.children[0]
      end
    end

    # Literals treated as expressions
    # NumericLiteral, IdentifierLiteral, StringLiteral
    if node.is(NumericLiteral, StringLiteral)
      return node.value
    end

    # Identifiers
    if node.is(IdentifierLiteral)
      return @symbols[node.value]
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
