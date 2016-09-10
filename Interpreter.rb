require_relative "syntax/AST.rb"
require_relative "misc/Helper.rb"

# Symbol to value container
class Stack
  attr_accessor :parent, :values

  def initialize(parent)
    @parent = parent
    @values = {}
  end

  def clear
    @values = {}
  end

  def depth(n = 0)
    if @parent
      return @parent.depth(n + 1)
    end
    return n
  end

  # Returns the stack for a given identifier
  def stack_for_key(k)
    if @values.key? k
      self
    else
      if @parent != NIL
        @parent.stack_for_key k
      else
        NIL
      end
    end
  end

  def []=(k, d, v)
    stack = stack_for_key k

    if d
      @values[k] = v
      return
    end

    unless stack == NIL
      stack.values[k] = v
    else
      raise "Variable '#{k}' not defined!"
    end
  end

  def [](k)
    if @values.key? k
      @values[k]
    else
      unless @parent == NIL
        @parent[k]
      else
        raise "Variable '#{k}' not defined!"
      end
    end
  end
end

# Runs a given program
class Interpreter
  attr_reader :symbols

  # Initialize the interpreter and insert all required programs
  def initialize(programs)
    @programs = programs

    # Bootstrap all stacks
    @all_stacks = []
    main = Stack.new NIL
    @all_stacks << main
    @stack = main
  end

  # Run all programs starting with the first one in the array
  def execute
    last_result = NIL
    @programs.each do |program|

      # Skip programs that are marked as not executable
      if !program.should_execute
        return
      end

      dlog "Executing program: #{yellow(program.file.filename)}"
      last_result = run_program program
    end
    last_result
  end

  # Executes a single program
  def run_program(program)

    # Check if the program contains a block
    if program.children.length == 1

      # The first node in the tree is always a block
      return run_block program.children[0], @stack
    end

    NIL
  end

  # Runs all expressions inside a given block
  def run_block(block, force_stack = NIL, arguments = NIL)

    # Backup and update the current stack
    old_stack = @stack

    # If a local stack is being forced upon the block
    if force_stack
      @stack = force_stack
    else
      @stack = Stack.new old_stack
    end

    # If the block has a predefined parent (functions)
    # assign the parent pointer
    if block.parent_stack
      @stack.parent = block.parent_stack
    end

    # Inject the arguments into the current stack
    if arguments
      arguments.each do |key, value|
        @stack[key, true] = value
      end
    end

    # A block contains a list of expressions
    # execute all of them
    last_result = NIL
    block.children.each do |expression|
      last_result = run_expression expression
    end

    # Revert to the original stack
    @stack = old_stack
    return last_result
  end

  # Executes a single expression and returns it's value
  def run_expression(node)

    # VariableInitialisation
    if node.is(VariableInitialisation)
      @stack[node.identifier.value, true] = run_expression node.expression
      return NIL
    end

    # VariableDeclaration
    if node.is(VariableDeclaration)
      @stack[node.identifier.value, true] = NIL
      return NIL
    end

    # VariableAssignment
    if node.is(VariableAssignment)
      value = run_expression node.expression
      @stack[node.identifier.value, false] = value
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
      function.block.parent_stack = @stack
      @stack[function.identifier.value, true] = function
      return NIL
    end

    # Call Expressions
    if node.is(CallExpression)

      # Resolve all arguments first
      arguments = []
      node.argumentlist.each do |argument|
        arguments << run_expression(argument)
      end

      # Check for an internal function call
      if node.identifier.value == "call_internal"
        return call_internal_function(arguments[0], arguments[1..-1])
      end

      # Check if the function is defined inside the symbols
      if @stack[node.identifier.value] && @stack[node.identifier.value].is(FunctionLiteral)

        # Get the list of arguments the function takes
        function = @stack[node.identifier.value]
        argument_ids = function.argumentlist.children.map do |argument|
          argument.value
        end

        # Check if the correct amount of arguments was passed
        if arguments.length != argument_ids.length
          raise "Expected #{argument_ids.length} arguments, got #{arguments.length} instead!"
        end

        # Create a hash for the arguments
        args = {}
        argument_ids.each_with_index do |id, index|
          args[id] = arguments[index]
        end

        return call_function(@stack[node.identifier.value], args)
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
      return @stack[node.value]
    end

    # Booleans
    if node.is(BooleanLiteral)
      return node.value
    end
  end

  # Execute a predefined function and return the last expression inside
  def call_function(function, arguments)
    run_block function.block, NIL, arguments
  end

  # Execute a given internal function
  def call_internal_function(name, arguments)
    case name
    when "print"
      arguments.each do |arg|
        if arg == NIL
          puts "NIL"
        else
          puts arg
        end
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
    when "variable"
      return @stack[arguments[0]]
    end
  end
end
