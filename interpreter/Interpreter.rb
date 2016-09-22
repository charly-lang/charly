require_relative "../syntax/AST.rb"
require_relative "stack.rb"
require_relative "types.rb"
require_relative "internal-functions.rb"
require_relative "../misc/Helper.rb"

# Runs a given program
class Interpreter
  attr_reader :last_result

  # Initialize the interpreter and insert all required programs
  def initialize(programs, stack)

    # Execute all programs
    @last_result = Executor.exec_programs(programs, stack)
  end
end

# Contains class methods to execute different nodes
class Executor

  # Execute a bunch of programs, each having access to a shared top stack
  def self.exec_programs(programs, stack)

    # Save the current program node
    program_backup = stack.program

    last_result = Types::NullType.new
    programs.each do |program|
      stack.program = program
      last_result = self.exec_program(program, stack)
      stack.program = program_backup
    end
    last_result
  end

  # Program node
  def self.exec_program(program, stack)

    # Check if the program should be executed
    unless program.should_execute
      dlog "Program #{yellow(program.file.fullpath)} is marked as not executable, skipping..."
      return Types::NumericType.new(1)
    end

    # Debugging
    dlog "Executing program: #{yellow(program.file.fullpath)}"

    # Check if the program contains a block
    if program.children.length == 1
      return self.exec_block(program.children[0], stack)
    end

    # If the program didn't contain anything,
    # return the NullType
    return Types::NullType.new
  end

  # Execute a single block,
  # also passing it a stack
  def self.exec_block(block, stack)
    last_result = Types::NullType.new
    block.children.each do |expression|
      last_result = self.exec_expression(expression, stack)
    end
    last_result
  end

  # Execute a single expression node
  def self.exec_expression(node, stack)
    if node.is VariableInitialisation
      return self.exec_variable_initialisation(node, stack)
    end

    if node.is VariableDeclaration
      return self.exec_variable_declaration(node, stack)
    end

    if node.is VariableAssignment
      return self.exec_variable_assignment(node, stack)
    end

    if node.is ArrayIndexWrite
      return self.exec_array_index_write(node, stack)
    end

    if node.is BinaryExpression
      return self.exec_binary_expression(node, stack)
    end

    if node.is ComparisonExpression
      return self.exec_comparison_expression(node, stack)
    end

    if node.is FunctionDefinitionExpression
      return self.exec_function_definition(node, stack)
    end

    if node.is ClassDefinition
      return self.exec_class_definition(node, stack)
    end

    if node.is ClassLiteral
      return self.connect_class_to_stack(node, stack)
    end

    if node.is CallExpression
      return self.exec_call_expression(node, stack)
    end

    if node.is WhileStatement
      return self.exec_while_statement(node, stack)
    end

    if node.is IfStatement
      return self.exec_if_statement(node, stack)
    end

    if node.is NumericLiteral, StringLiteral, BooleanLiteral, ArrayLiteral
      return self.exec_literal(node, stack)
    end

    if node.is IdentifierLiteral
      return self.exec_identifier_literal(node, stack)
    end

    if node.is FunctionLiteral
      return self.connect_function_to_stack(node, stack)
    end

    # Nested expressions inside a statement
    if node.is(Statement) && node.children.length == 1
      if node.children[0].is Expression, NumericLiteral, StringLiteral, IdentifierLiteral
        return self.exec_expression(node.children[0], stack)
      end
    end

    return Types::NullType.new
  end

  # Execute a variable initialisation
  # Saves a variable into the current stack
  # the return value is the value of the variable
  def self.exec_variable_initialisation(node, stack)
    value = self.exec_expression(node.expression, stack)
    stack[node.identifier.value, true] = value
    value
  end

  # Execute a variable initialisation
  # Reserves a variable in the current stack
  # the return value is NULL
  def self.exec_variable_declaration(node, stack)
    value = Types::NullType.new
    stack[node.identifier.value, true] = value
    value
  end

  # Assign a value to a variable inside the current stack
  # the return value is the value of the identifier
  # after the assignment
  def self.exec_variable_assignment(node, stack)
    value = self.exec_expression(node.expression, stack)
    stack[node.identifier.value, false] = value

    # Return value is the value of the variable
    # after the assignment
    #
    # not the value passed in
    return stack[node.identifier.value]
  end

  # Assign a value to an index inside an array
  def self.exec_array_index_write(node, stack)
    identifier = node.children[0].value
    location = node.children[1].children.map do |child|
      self.exec_expression(child, stack)
    end
    expression = self.exec_expression(node.children[2], stack)

    # Get the right array from the stack
    array = stack[identifier]

    # Check if the value we got from the stack is really an array
    if !array.is_a? Types::ArrayType
      raise "#{identifier} is not an array."
    end

    # Iterate over the indexes
    location.each_with_index do |loc, index|

      # Check if the current location is the last
      if index == location.length - 1

        # This is the last index
        array.value[loc.value] = expression
      else

        # Check if the values are an array
        if !array.value.is_a? Array
          raise "Index #{loc.value} is not an array"
        end

        # Check for out-of-bounds errors
        if loc.value < 0 || loc.value > array.value.length - 1
          raise "Index #{loc.value} is out of bounds"
        end

        # Update the array pointer
        array = array.value[loc.value]
      end
    end

    expression
  end

  # Perform a binary expression
  def self.exec_binary_expression(node, stack)
    left = self.exec_expression(node.left, stack)
    right = self.exec_expression(node.right, stack)

    # TODO: Type-check and possibly do casting?
    result = Types::NullType.new
    result = case node.operator
    when PlusOperator
      left + right
    when MinusOperator
      left - right
    when MultOperator
      left * right
    when DivdOperator
      left / right
    when ModOperator
      left % right
    when PowOperator
      left ** right
    end

    return Types.new(result)
  end

  # Perform a comparison operation
  def self.exec_comparison_expression(node, stack)
    left = self.exec_expression(node.left, stack).value
    right = self.exec_expression(node.right, stack).value

    case node.operator
    when GreaterOperator
      return Types::BooleanType.new(left > right)
    when SmallerOperator
      return Types::BooleanType.new(left < right)
    when GreaterEqualOperator
      return Types::BooleanType.new(left >= right)
    when SmallerEqualOperator
      return Types::BooleanType.new(left <= right)
    when EqualOperator
      if left.is_a?(Types::ArrayType) && right.is_a?(Types::ArrayType)
        if left.value.count == right.value.count

          # Check each property in the array and compare it to the corresponding in the other one
          equal = false
          left.value.each_with_index do |left_value, index|

            # Construct a comparison node from the ast
            comparison = ComparisonExpression.new("==", left_value, right.value[index], node.parent)
            equal = self.exec_comparison_expression(comparison, stack) unless equal
          end
          return Types::BooleanType.new(equal)
        else
          return Types::BooleanType.new(false)
        end
      else
        return Types::BooleanType.new(left == right)
      end
    when NotEqualOperator
      return Types::BooleanType.new(left != right)
    end
  end

  # Define a function in the current stack
  def self.exec_function_definition(node, stack)
    function = self.connect_function_to_stack(node.function, stack)

    # If the function is anonymous, it should not be saved inside the stack
    if function.identifier == nil
      function
    else
      stack[function.identifier.value, true] = function
      stack[function.identifier.value]
    end
  end

  # Define a class in the current stack
  def self.exec_class_definition(node, stack)
    classliteral = self.connect_class_to_stack(node.classliteral, stack)

    # Save it inside the stack
    stack[classliteral.identifier.value, true] = classliteral
    stack[classliteral.identifier.value]
  end

  # Execute a call expression
  # returns the result of the expression
  def self.exec_call_expression(node, stack)

    # Evaluate all arguments first
    arguments = []
    node.argumentlist.each do |argument|
      arguments << self.exec_expression(argument, stack)
    end

    # Get the function that's being executed
    function = Types::NullType.new

    # check if the function is a function literal
    if node.identifier.is(IdentifierLiteral)

      # Check for an internal function call
      if node.identifier.value == "call_internal"
        return Interpreter::InternalFunctions.exec_internal_function(arguments[0], arguments[1..-1], stack, node)
      end

      # Check the stack for a function definition
      stack_value = stack[node.identifier.value]

      # Return the corresponding item if an array was found
      if stack_value.is_a? Types::ArrayType
        arguments.each do |arg|

          # Check if something else than a NumericType was passed
          if !arg.is_a? Types::NumericType
            raise "Array index operator expected Types::NumericType, got #{arg.class}"
          end

          # Check for out of bounds errors
          if arg.value < 0 || arg.value > (stack_value.value.length - 1)
            return Types::NullType.new
          end

          stack_value = stack_value.value[arg.value]
        end

        return stack_value
      end

      function = stack_value
    elsif node.identifier.is(Types::FuncType)
      function = self.connect_function_to_stack(node.identifier, stack)
    elsif node.identifier.is(CallExpression)
      function = self.exec_call_expression(node.identifier, stack)
    end

    # Check if function is really a function
    if !function.is Types::FuncType
      raise "#{function} is not a function!"
    end

    # Get the identities of the arguments that are required
    argument_ids = function.argumentlist.children.map do |argument|
      argument.value
    end

    # Check if the correct amount of arguments was passed
    if arguments.length < argument_ids.length
      if function.identifier.is_a? NilClass
        raise "Anonymous function expected #{argument_ids.length} argument(s), got #{arguments.length} instead!"
      else
        raise "#{function.identifier.value} expected #{argument_ids.length} argument(s), got #{arguments.length} instead!"
      end
    end

    # Create new stack for the function arguments to be saved in
    # and to be passed to self.exec_block
    function_stack = Stack.new(function.block.parent_stack)
    function_stack["__arguments__", true] = Types::ArrayType.new arguments
    arguments.each_with_index do |arg, index|
      function_stack[argument_ids[index], true] = arg
    end

    # Execute the block
    return self.exec_block(function.block, function_stack)
  end

  # Execute a while statement
  # the return value of the while statement is the last expression
  # inside the last block executed
  def self.exec_while_statement(node, stack)
    last_result = Types::NullType.new
    while self.eval_bool(self.exec_expression(node.test, stack), stack) do
      last_result = self.exec_block(node.consequent, Stack.new(stack))
    end
    last_result
  end

  # Execute an if statement
  # the return value is the last expression in the last block executed
  def self.exec_if_statement(node, stack)

    # Evaluate the test expression
    test_result = self.eval_bool(self.exec_expression(node.test, stack), stack)

    # Run the respective handler
    if test_result
      return self.exec_block(node.consequent, Stack.new(stack))
    else
      if node.alternate
        if node.alternate.is(IfStatement)
          return self.exec_if_statement(node.alternate, stack)
        elsif node.alternate.is(Block)
          return self.exec_block(node.alternate, Stack.new(stack))
        end
      end
    end
  end

  # Cast a literal node of the ast
  # into the runtime representation of values
  def self.exec_literal(node, stack)
    case node
    when NumericLiteral
      return Types::NumericType.new(node.value)
    when StringLiteral
      return Types::StringType.new(node.value)
    when BooleanLiteral
      return Types::BooleanType.new(node.value)
    when NullLiteral
      return Types::NullLiteral.new
    when ArrayLiteral
      children = []
      node.children[0].children.each do |child|
        children << self.exec_expression(child, stack)
      end

      return Types::ArrayType.new(children)
    end
  end

  # Return the value of an identifier
  def self.exec_identifier_literal(node, stack)
    return stack[node.value]
  end

  # Inline function literal
  # this just connects the function to the right parent stack
  def self.connect_function_to_stack(node, stack)
    Types::FuncType.new(
      node.identifier,
      node.argumentlist,
      node.block,
      stack
    )
  end

  # Inline class literal
  # This just connects the class to the right parent stack
  def self.connect_class_to_stack(node, stack)
    Types::ClassType.new(
      node.identifier,
      node.initializer,
      node.block,
      stack
    )
  end

  # Returns true or false for a given value
  def self.eval_bool(value, stack)
    case value
    when Types::NumericType
      return value.value != 0
    when Types::BooleanType::True
      return true
    when Types::BooleanType::False
      return false
    when TrueClass
      true
    when FalseClass
      false
    else
      return true
    end
  end
end
