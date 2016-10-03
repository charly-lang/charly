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
        puts last_result
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

      if node.is_a? NumericLiteral | StringLiteral | BooleanLiteral | ArrayLiteral
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
          stack.write(identifier_value, value, true)
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
        if identifier.is_a? IdentifierLiteral
          identifier_value = identifier.value
          if identifier_value.is_a? String
            stack.write(identifier_value, value)
          end
        end
      end

      value
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
      when NullLiteral
        return TNull.new
      when ArrayLiteral

        # Resolve all children
        values = node.children.map do |child|
          self.exec_expression(child, stack).as BaseType
        end

        return TArray.new(values)
      end

      raise "Invalid literal found"
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
