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

    if node.is CallExpression
      return self.exec_call_expression(node, stack)
    end

    if node.is MemberExpression
      return self.exec_member_expression(node, stack)
    end

    if node.is WhileStatement
      return self.exec_while_statement(node, stack)
    end

    if node.is IfStatement
      return self.exec_if_statement(node, stack)
    end

    if node.is NumericLiteral, StringLiteral, BooleanLiteral, ArrayLiteral, FunctionLiteral, ClassLiteral
      return self.exec_literal(node, stack)
    end

    if node.is IdentifierLiteral
      return self.exec_identifier_literal(node, stack)
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
    stack.write(node.identifier.value, value, true)
    value
  end

  # Execute a variable initialisation
  # Reserves a variable in the current stack
  # the return value is NULL
  def self.exec_variable_declaration(node, stack)
    value = Types::NullType.new
    stack.write(node.identifier.value, value, true)
    value
  end

  # Assign a value to a variable inside the current stack
  # the return value is the value of the identifier
  # after the assignment
  def self.exec_variable_assignment(node, stack)

    # Resolve the value of the expression
    value = self.exec_expression(node.expression, stack)

    # Check if node is a member expression
    if node.identifier.is(MemberExpression)

      # Resolve the left-hand side of the expression
      # up the top level but not including it
      # Top(not-resolved) -> left(resolved) -> left(resolved)
      identifier = node.identifier.identifier
      member = node.identifier.member

      # Resolving
      identifier = self.exec_expression(identifier, stack)

      # Check if the identifier is an object
      if !identifier.is(Types::ObjectType)
        raise "'#{identifier}' is not an object!"
      end

      # Perform the write on the objects stack
      identifier.stack.write(member.value, value, false, false)
    else
      stack.write(node.identifier.value, value, false)
    end

    return value
  end

  # Assign a value to an index inside an array
  def self.exec_array_index_write(node, stack)

    if !node.children[0].is(IdentifierLiteral)
      array = self.exec_expression(node.children[0], stack)
    else
      array = stack.get(node.children[0].value)
    end

    location = node.children[1].children.map do |child|
      self.exec_expression(child, stack)
    end
    expression = self.exec_expression(node.children[2], stack)

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

    return expression
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
    function = self.exec_literal(node.function, stack)

    # If the function is anonymous, it should not be saved inside the stack
    if function.identifier == nil
      function
    else
      stack.write(function.identifier.value, function, true)
      stack.get(function.identifier.value)
    end
  end

  # Define a class in the current stack
  def self.exec_class_definition(node, stack)
    classliteral = self.exec_literal(node.classliteral, stack)

    # Save it inside the stack
    stack.write(classliteral.identifier.value, classliteral, true)
    stack.get(classliteral.identifier.value)
  end

  # Execute a call expression
  # returns the result of the expression
  def self.exec_call_expression(node, stack)

    # Evaluate all arguments first
    arguments = []
    node.argumentlist.each do |argument|
      arguments << self.exec_expression(argument, stack)
    end

    # Get the identifier of the call expression
    # If the identifier is an IdentifierLiteral we first check if it's a "call_internal" call
    function = nil
    if node.identifier.is(IdentifierLiteral)

      # Check for an internal function call
      if node.identifier.value == "call_internal"
        return Interpreter::InternalFunctions.exec_internal_function(arguments[0], arguments[1..-1], stack, node)
      end

      function = stack.get(node.identifier.value)
    else

      # Resolve the identifier
      function = self.exec_expression(node.identifier, stack)
    end

    # Return the corresponding item if an array was found
    if function.is_a? Types::ArrayType
      arguments.each do |arg|

        # Check if something else than a NumericType was passed
        if !arg.is_a? Types::NumericType
          raise "Array index operator expected Types::NumericType, got #{arg.class}"
        end

        # Check for out of bounds errors
        if arg.value < 0 || arg.value > (function.value.length - 1)
          return Types::NullType.new
        end

        function = function.value[arg.value]
      end

      return function
    end

    # Check if function is really a function
    if !function.is Types::FuncType
      puts node
      raise "#{function} is not a function!"
    end

    # Execute the function
    return self.exec_function(function, arguments)
  end

  # Perform a member lookup
  def self.exec_member_expression(node, stack)

    # Get some values
    ident = self.exec_expression(node.identifier, stack)
    member = node.member.value

    # Check if ident is an object
    if !ident.is(Types::ObjectType)
      raise "#{ident} is not an object!"
    end

    # Check the stack for the value
    if ident.stack.contains(member)
      return ident.stack.get(member)
    else
      return Types::NullType.new
    end
  end

  # Instantiate a new instance of *ident*
  # Passing the contructor *arguments*
  def self.exec_object_instantiation(ident, arguments, stack)

    # Create a new stack for the constructor to run in
    object_stack = Stack.new ident.parent_stack

    # Execute the class block
    self.exec_block(ident.block, object_stack)

    # Execute the constructor inside the object_stack
    if object_stack.contains("constructor")
      self.exec_function(object_stack.get("constructor"), arguments);
    end

    # Lock the stack to prevent further variable declarations
    # and remove the constructor
    object_stack.lock
    object_stack.values.delete "constructor"

    # Create the ObjectType instance
    return Types::ObjectType.new(ident, object_stack)
  end

  # Execute a given function
  # Passing it some arguments
  # Inside a stack
  def self.exec_function(function, arguments, stack = nil)

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
    function_stack = Stack.new(stack || function.block.parent_stack)
    function_stack.write("__arguments__", Types::ArrayType.new(arguments), true)
    arguments.each_with_index do |arg, index|
      function_stack.write(argument_ids[index], arg, true)
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
    when FunctionLiteral
      Types::FuncType.new(
        node.identifier,
        node.argumentlist,
        node.block,
        stack
      )
    when ClassLiteral
      Types::ClassType.new(
        node.identifier,
        self.exec_literal(node.constructor, stack),
        node.block,
        stack
      )
    end
  end

  # Return the value of an identifier
  def self.exec_identifier_literal(node, stack)
    return stack.get(node.value)
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
    when Types::NullType
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
