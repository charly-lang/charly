require_relative "Helper.rb"
require_relative "Parser.rb"
require_relative "AST.rb"

# Optimizes a program to be more efficient
# Doesn't always produce the "perfect" program
class Optimizer

  def initialize
    @structure_finished = false
    @grouping_finished = false
  end

  # Optimize a program
  def optimize_program(program)
    if !program.is Program
      raise "Not a Program instance"
    end

    dlog "- Optimizing program structure"
    while !@structure_finished
      @structure_finished = true
      optimize :structure, program
    end
    dlog "- Finished optimizing program structure"

    dlog "- Generating abstract syntax tree groupings"
    while !@grouping_finished
      @grouping_finished = true
      optimize :group, program, true
    end
    dlog "- Finished generating abstract syntax tree groupings"

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

    # Term nodes that only have 1 terminal child,
    # should be replaced by that child
    if node.is Term
      if node.children.length == 1
        child = node.children[0]
        if child.is Terminal
          @structure_finished = false
          return child
        end
      end
    end

    # Expression nodes that only have 1 terminal child,
    # should be replaced by that child
    if node.is Expression
      if node.children.length == 1
        child = node.children[0]
        if child.is Terminal
          @structure_finished = false
          return child
        end
      end
    end

    # Expression nodes that only have 1 Expression child,
    # should be replaced by that child
    if node.is Expression
      if node.children.length == 1
        child = node.children[0]
        if child.is Expression
          @structure_finished = false
          return child
        end
      end
    end

    # Term nodes that only have 1 Expression child,
    # should be replaced by that child
    if node.is Term
      if node.children.length == 1
        child = node.children[0]
        if child.is Expression
          @structure_finished = false
          return child
        end
      end
    end

    # Remove LEFT_PAREN, RIGHT_PAREN, SEMICOLON nodes
    if node.is LeftParenLiteral, RightParenLiteral, SemicolonLiteral, CommaLiteral
      @structure_finished = false
      return NIL
    end

    node
  end

  # Optimize the groupings of the node
  def flow_group(node)

    # Group arithmetic operations together
    if node.is(Expression) && node.children.length == 3
      child1 = node.children[0]
      child2 = node.children[1]
      child3 = node.children[2]

      # Check if child 2 is an operator
      if child2.is OperatorLiteral

        # Typecheck child1 and child2
        if child1.is(NumericLiteral, IdentifierLiteral, Expression) &&
          child3.is(NumericLiteral, IdentifierLiteral, Expression)

          expression = BinaryExpression.new(child2, child1, child3, node.parent)
          @grouping_finished = false
          return expression
        end
      end
    end

    # Group Variable Assignments together
    if node.is(Statement) && node.children.length == 4
      if node.children[2].is AssignmentOperator
        identifier = node.children[1]
        expression = node.children[3]

        assignment = VariableAssignment.new(identifier, expression, node.parent)
        @grouping_finished = false
        return assignment
      end
    end

    node
  end
end
