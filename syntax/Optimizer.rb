require_relative "../misc/Helper.rb"
require_relative "Parser.rb"
require_relative "AST.rb"

# Optimizes a program to be more efficient
# Doesn't always produce the "perfect" program
class Optimizer

  def initialize
    @finished = false
  end

  # Optimize a program
  def optimize_program(program)
    if !program.is Program
      raise "Not a Program instance"
    end

    dlog "Optimizing program structure"
    while !@finished
      @finished = true
      optimize :structure, program
    end

    # Reset @finished
    @finished = false

    dlog "Generating abstract syntax tree groupings"
    while !@finished
      @finished = true
      optimize :group, program, true
    end

    program
  end

  # Optimize a node with a given flow
  # options are:
  # - structure
  # - group
  def optimize(flow, node, after = false)

    # Backup the parent
    parent_save = node.parent

    # Call the entry handler
    unless after
      case flow
      when :structure
        node = flow_structure node
      when :group
        node = flow_group node
      end

      # Return if the node returned NIL
      if node == NIL
        return NIL
      end

      # Correct the parent pointer
      node.parent = parent_save
    end


    # Optimize all children and remove nil values afterwards
    node.children.collect! do |child|
      case flow
      when :structure
        optimize :structure, child, after
      when :group
        optimize :group, child, after
      end
    end
    node.children = node.children.compact

    # Call the leave handler
    if after
      case flow
      when :structure
        node = flow_structure node
      when :group
        node = flow_group node
      end

      # Return if the node returned NIL
      if node == NIL
        return NIL
      end

      # Correct the parent pointer
      node.parent = parent_save
    end

    node
  end

  # Optimize the structure of a node
  def flow_structure(node)

    # NumericLiterals value property should be an actual INT
    if node.is(NumericLiteral) && node.value.is_a?(String)
      node.value = node.value.to_f
      @finished = false
      return node
    end

    # Expressions that only contain 1 other expression
    # should be replaced by that expression
    if node.is(Expression) && node.children.length == 1
      if node.children[0].is(Expression)
        @finished = false
        return node.children[0]
      end
    end

    # Expression that only contain terminal nodes
    # that can be treated as expressions
    # should be replaced by that nodes
    if node.is(Expression) && node.children.length == 1
      if node.children[0].is NumericLiteral, StringLiteral, IdentifierLiteral
        @finished = false
        return node.children[0]
      end
    end

    # Strip semicolons, commas
    if node.is(CommaLiteral, SemicolonLiteral)
      @finished = false
      return NIL
    end

    node
  end

  # Optimize the groupings of the node
  def flow_group(node)

    # Arithmetic expressions involving an operator
    if node.is(Expression) && node.children.length == 3

      # Check for the operator
      if node.children[1].is(BinaryOperatorLiteral)

        # Typecheck left and right argument
        left = node.children[0]
        right = node.children[2]
        operator = node.children[1]

        if left.is Expression, NumericLiteral, StringLiteral, IdentifierLiteral
          if right.is Expression, NumericLiteral, StringLiteral, IdentifierLiteral

            @finished = false
            return BinaryExpression.new(operator, left, right, node.parent)
          end
        end
      end
    end

    # Assignment operator
    if node.is(Expression) && node.children.length == 3

      # Check for the operator
      if node.children[1].is(AssignmentOperator)

        # Typecheck left and right argument
        identifier = node.children[0]
        expression = node.children[2]
        operator = node.children[1]

        if identifier.is IdentifierLiteral
          if expression.is Expression, NumericLiteral, StringLiteral, IdentifierLiteral

            @finished = false
            return VariableAssignment.new(identifier, expression, node.parent)
          end
        end
      end
    end

    # Declarations
    if node.is(Statement) && node.children.length == 3

      # Check for the let keyword
      if node.children[0].value == "let"
        if node.children[1].is(IdentifierLiteral)

          @finished = false
          return VariableDeclaration.new(node.children[1], node.parent)
        end
      end
    end

    # Variable initialisations
    if node.is(Statement) && node.children.length == 4
      child1 = node.children[0]
      child2 = node.children[1]
      child3 = node.children[2]
      child4 = node.children[3]

      if child1.is(KeywordLiteral) && child1.value == "let"
        if child2.is(IdentifierLiteral) && child3.is(AssignmentOperator)
          if child4.is(Expression, NumericLiteral, StringLiteral, IdentifierLiteral)

            @finished = false
            return VariableInitialisation.new(child2, child4, node.parent)
          end
        end
      end
    end

    # Call Expressions
    if node.is(Statement, Expression) && node.children.length == 4
      child1 = node.children[0]
      child2 = node.children[1]
      child3 = node.children[2]
      child4 = node.children[3]

      if child1.is(IdentifierLiteral) && child3.is(ExpressionList)
        if child2.is(LeftParenLiteral) && child4.is(RightParenLiteral)

          @finished = false
          return CallExpression.new(child1, child3, node.parent)
        end
      end
    end

    node
  end
end
