require_relative "syntax/AST.rb"
require_relative "misc/Helper.rb"

# Symbol to value container
class SymbolContainer

  class SingleSymbol
    attr_accessor :identifier, :value

    def initialize(identifier, value)
      @identifier = identifier
      @value = value
    end
  end

  attr_accessor :raw_symbols

  def initialize
    @raw_symbols = {}
  end

  # Get a specific symbol
  def [](k)
    @raw_symbols[k]
  end

  # Set a specific symbol
  def []=(k, v)
    @raw_symbols[k] = v
  end
end

# Runs a given program
class Interpreter
  attr_reader :symbols

  # Initialize the interpreter and insert all required programs
  def initialize(programs)
    @programs = programs
    @symbols = SymbolContainer.new
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
      @symbols[node.identifier.value] = run_expression node.expression
      return NIL
    end

    # VariableDeclaration
    if node.is(VariableDeclaration)
      @symbols[node.identifier.value] = NIL
      return NIL
    end

    # VariableAssignment
    if node.is(VariableAssignment)
      value = run_expression node.expression
      @symbols[node.identifier.value] = value
      return value
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

    # FunctionDefinitionExpressions
    if node.is(FunctionDefinitionExpression)
      function = node.function
      @symbols[function.identifier.value] = function
      return NIL
    end

    # Call Expressions
    if node.is(CallExpression)

      # Resolve all arguments first
      arguments = []
      node.argumentlist.each do |argument|
        arguments << run_expression(argument)
      end

      # Check if the function is defined inside the symbols
      if @symbols[node.identifier.value] && @symbols[node.identifier.value].is(FunctionLiteral)
        return call_function(@symbols[node.identifier.value], arguments)
      else
        return call_internal_function(node.identifier.value, arguments)
      end
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

    # Literals treated as expressions
    # NumericLiteral, IdentifierLiteral, StringLiteral
    if node.is(FunctionLiteral)
      return node
    end

    # Identifiers
    if node.is(IdentifierLiteral)
      return @symbols[node.value]
    end
  end

  # Execute a predefined function and return the last expression inside
  def call_function(function, arguments)
    run_block function.block
  end

  # Execute a given internal function
  def call_internal_function(name, arguments)
    case name
    when "print"
      arguments.each do |arg|
        puts arg
      end
      return NIL
    when "Number"
      return arguments[0].to_f
    when "String"
      return arguments[0].to_s
    when "gets"
      input = $stdin.gets
      return input
    when "chomp"
      return arguments[0].chomp
    when "sleep"
      sleep(arguments[0])
      return NIL
    end
  end
end
