require "../syntax/ast/ast.cr"
require "./stack.cr"
require "./session.cr"
require "./types.cr"

# Provides a higher-level interface to the executor
class Interpreter
  include CharlyTypes
  property program_result : BaseType

  def initialize(programs, stack)
    @program_result = Executor.exec_programs(programs, stack)
  end

  # Execute a given *node* in a given *stack*
  class Executor

    # Execute a bunch of programs, each having access to a shared top stack
    def self.exec_programs(programs, stack)
      last_result = TNull.new
      programs.map do |program|
        last_result = self.exec_program(program, stack)
      end
      last_result
    end

    # Executes *program* inside *stack*
    def self.exec_program(program, stack)
      self.exec_block(program.children[0], stack)
    end

    # Executes *node* inside *stack*
    def self.exec_block(node, stack)
      last_result = TNull.new
      node.children.each do |expression|
        last_result = self.exec_expression(expression, stack)
      end
      last_result
    end

    # Executes *node* inside *stack*
    def self.exec_expression(node, stack)

      if node.is_a? VariableDeclaration
        return self.exec_variable_declaration(node, stack)
      end

      if node.is_a? VariableInitialisation
        return self.exec_variable_initialisation(node, stack)
      end

      if node.is_a? VariableAssignment
        return self.exec_variable_assignment(node, stack)
      end

      if node.is_a? UnaryExpression
        return self.exec_unary_expression(node, stack)
      end

      if node.is_a? BinaryExpression
        return self.exec_binary_expression(node, stack)
      end

      if node.is_a? ComparisonExpression
        return self.exec_comparison_expression(node, stack)
      end

      if node.is_a? IdentifierLiteral
        return self.exec_identifier_literal(node, stack)
      end

      if node.is_a? CallExpression
        return self.exec_call_expression(node, stack)
      end

      if node.is_a? IfStatement
        return self.exec_if_statement(node, stack)
      end

      if node.is_a? WhileStatement
        return self.exec_while_statement(node, stack)
      end

      if node.is_a? NumericLiteral | StringLiteral | BooleanLiteral | FunctionLiteral
        return self.exec_literal(node, stack)
      end

      raise "Unknown node encountered #{node.class} #{stack}"
    end

    # Initializes a variable in the current stack
    # The value is set to TNull
    def self.exec_variable_declaration(node, stack)
      value = TNull.new
      identifier = node.identifier
      if identifier.is_a?(IdentifierLiteral)
        identifier_value = identifier.value
        if identifier_value.is_a?(String)
          stack.write(identifier_value, value, true)
        end
      end
      return value
    end

    # Saves value to a given variable in the current stack
    def self.exec_variable_initialisation(node, stack)

      # Resolve the value
      value = self.exec_expression(node.expression, stack)

      # Check for the identifier
      identifier = node.identifier
      if identifier.is_a? IdentifierLiteral
        identifier_value = identifier.value
        if identifier_value.is_a? String

          if value.is_a? BaseType
            stack.write(identifier_value, value, true)
          end
        end
      end
      return value
    end

    # Assign the result of an expression to a variable
    # in the current stack
    def self.exec_variable_assignment(node, stack)

      # Resolve the expression
      value = self.exec_expression(node.expression, stack)

      # Check if this is a member expression
      if node.identifier.is_a? MemberExpression
        raise "Member expressions are not yet supported"
      else

        identifier = node.identifier
        if identifier.is_a?(IdentifierLiteral)

          identifier_value = identifier.value
          if identifier_value.is_a?(String)

            # Check that the value is a BaseType
            if value.is_a? BaseType
              stack.write(identifier_value, value)
            end
          end
        end
      end

      value
    end

    # Extracts the value of a variable from the current stack
    def self.exec_identifier_literal(node, stack)
      stack.get(node.value)
    end

    def self.exec_unary_expression(node, stack)

      # Resolve the right side
      right = self.exec_expression(node.right, stack)

      case node.operator
      when MinusOperator
        if right.is_a? TNumeric
          return TNumeric.new(-right.value)
        end
      when NotOperator
        return TBoolean.new(!self.eval_bool(right, stack))
      end

      raise "Invalid operator or right-hand-side in unary expression"
    end

    def self.exec_binary_expression(node, stack)

      # Resolve the left and right side
      operator = node.operator
      left = self.exec_expression(node.left, stack)
      right = self.exec_expression(node.right, stack)

      case node.operator
      when PlusOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value + right.value)
        end
      when MinusOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value - right.value)
        end
      when MultOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value * right.value)
        end
      when DivdOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value / right.value)
        end
      when ModOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value % right.value)
        end
      when PowOperator
        if left.is_a?(TNumeric) && right.is_a?(TNumeric)
          return TNumeric.new(left.value ** right.value)
        end
      end

      raise "Invalid types or values inside binary expression"
    end

    # Perform a comparison
    def self.exec_comparison_expression(node, stack)

      # Resolve the left and right side
      left = self.exec_expression(node.left, stack)
      right = self.exec_expression(node.right, stack)
      operator = node.operator

      # When comparing TNumeric's
      if left.is_a?(TNumeric) && right.is_a?(TNumeric)

        # Different types of operators
        case operator
        when GreaterOperator
          return TBoolean.new(left.value > right.value)
        when LessOperator
          return TBoolean.new(left.value < right.value)
        when GreaterEqualOperator
          return TBoolean.new(left.value >= right.value)
        when LessEqualOperator
          return TBoolean.new(left.value <= right.value)
        when EqualOperator
          return TBoolean.new(left.value == right.value)
        when NotOperator
          return TBoolean.new(left.value != right.value)
        end
      end

      # When comparing TBools
      if left.is_a?(TBoolean) && right.is_a?(TBoolean)
        case operator
        when GreaterOperator, LessOperator, GreaterEqualOperator, LessEqualOperator
          return TBoolean.new(false)
        when EqualOperator
          return TBoolean.new(left.value == right.value)
        when NotOperator
          return TBoolean.new(left.value != right.value)
        end
      end

      # When comparing strings
      if left.is_a?(TString) && right.is_a?(TString)
        case operator
        when GreaterOperator
          return TBoolean.new(left.value.size > right.value.size)
        when LessOperator
          return TBoolean.new(left.value.size < right.value.size)
        when GreaterEqualOperator
          return TBoolean.new(left.value.size >= right.value.size)
        when LessEqualOperator
          return TBoolean.new(left.value.size <= right.value.size)
        when EqualOperator
          return TBoolean.new(left.value == right.value)
        when NotOperator
          return TBoolean.new(left.value != right.value)
        end
      end

      # When comparing TFunc
      if left.is_a?(TFunc) && right.is_a?(TFunc)
        case operator
        when GreaterOperator, LessOperator, GreaterEqualOperator, LessEqualOperator
          return TBoolean.new(false)
        when EqualOperator
          return TBoolean.new(left == right)
        when NotOperator
          return TBoolean.new(left != right)
        end
      end

      # If the left side is null
      if left.is_a? TNull
        case operator
        when GreaterOperator, LessOperator, GreaterEqualOperator, LessEqualOperator
          return TBoolean.new(false)
        when EqualOperator
          return TBoolean.new(left.class == right.class)
        when NotOperator
          return TBoolean.new(left.class != right.class)
        end
      end

      # Make sure that the left side
      # is of the same type as the right side
      if left.class != right.class
        return TBoolean.new(false)
      end

      # Raise when an unknown operator is found
      raise "Invalid comparison found #{node}"
    end

    # Execute an if statement
    def self.exec_if_statement(node, stack)

      # Resolve the test expression
      test = node.test
      if test.is_a?(ASTNode)
        test_result = self.eval_bool(self.exec_expression(node.test, stack), stack)
      else
        return TNull.new
      end

      # Run the respective handler
      if test_result
        consequent = node.consequent
        if consequent.is_a?(Block)
          return self.exec_block(consequent, Stack.new(stack, stack.session))
        end
      else
        alternate = node.alternate
        if alternate.is_a?(ASTNode)
          if alternate.is_a?(IfStatement)
            return self.exec_if_statement(alternate, stack)
          elsif node.alternate.is_a?(Block)
            return self.exec_block(alternate, Stack.new(stack, stack.session))
          end
        end
      end

      # Sanity check
      return TNull.new
    end

    # Executes a while node
    def self.exec_while_statement(node, stack)

      # Typecheck
      test = node.test
      consequent = node.consequent

      if test.is_a?(ASTNode) && consequent.is_a?(ASTNode)
        last_result = TNull.new
        while self.eval_bool(self.exec_expression(test, stack), stack)
          last_result = self.exec_block(consequent, Stack.new(stack, stack.session))
        end
        return last_result
      else
        return TNull.new
      end
    end

    # Executes a call expression
    def self.exec_call_expression(node, stack)

      # Resolve all arguments
      arguments = [] of BaseType
      argumentlist = node.argumentlist
      if argumentlist.is_a? ExpressionList
        argumentlist.each do |argument|
          arguments << self.exec_expression(argument, stack)
        end
      end

      # Get the identifier of the call expression
      # If the identifier is an IdentifierLiteral we first check
      # if it's a call to "call_internal"
      # we are redirecting this
      identifier = node.identifier
      if identifier.is_a? IdentifierLiteral

        # Check for the "call_internal" name
        if identifier.value == "call_internal"
          raise "Calls to call_internal are not yet supported!"
        else
          function = stack.get(identifier.value)
        end
      else
        function = self.exec_expression(node.identifier, stack)
      end

      # Check if a function was found
      unless function.is_a? TFunc
        raise "#{identifier} is not a function!"
      end

      # Execute the function
      return self.exec_function(function, arguments, stack)
    end

    # Executes *function*, passing it *arguments*
    # inside *stack*
    # *function* is of type TFunc
    # *arguments* is an actual array of RunTimeType values
    def self.exec_function(function, arguments, stack)

      # Create the new stack for the function to run in
      if stack.is_a? Stack
        function_stack = Stack.new(stack, stack.session)
      else

        # Check if there is a parent stack
        parent_stack = function.block.parent_stack
        if parent_stack.is_a? Stack
          function_stack = Stack.new(parent_stack, parent_stack.session)
        else
          raise "Could not find a valid stack for the function to run in"
        end
      end

      # Get the identities of the arguemnts that are required
      argument_ids = function.argumentlist.map { |argument|
        if argument.is_a? IdentifierLiteral && argument.value.is_a? String
          result = argument.value
        end
      }.compact

      # Write the argument to the function stack
      arguments.each_with_index do |arg, index|
        id = argument_ids[index]

        if id.is_a? String
          function_stack.write(id, arg, true)
        end
      end

      # Check if the correct amount of arguments was passed
      if arguments.size < argument_ids.size
        raise "Function expected #{argument_ids.size} arguments, got #{arguments.size}"
      end

      # Execute the block
      return self.exec_block(function.block, function_stack)
    end

    def self.exec_literal(node, stack)
      case node
      when NumericLiteral
        value = node.value
        if value.is_a?(String)
          return TNumeric.new(value.to_f)
        end
      when StringLiteral
        value = node.value
        if value.is_a?(String)
          return TString.new(value)
        end
      when BooleanLiteral
        value = node.value
        if value.is_a?(String)
          return TBoolean.new(value == "true")
        end
      when FunctionLiteral
        argumentlist = node.argumentlist
        block = node.block

        if argumentlist.is_a? ASTNode && block.is_a? Block
          return TFunc.new(argumentlist.children, block, stack)
        end
      when ClassLiteral
        block = node.block

        if block.is_a? Block
          return TClass.new(block, stack)
        end
      when NullLiteral
        return TNull.new
      end

      raise "Invalid literal found #{node.class}"
    end

    # Returns the boolean representation of a value
    def self.eval_bool(value, stack)
      case value
      when TNumeric
        return value.value != 0
      when TBoolean
        return value.value
      when TString
        return true
      when TFunc
        return true
      when TNull
        return false
      when Bool
        return value
      else
        return false
      end
    end
  end
end
