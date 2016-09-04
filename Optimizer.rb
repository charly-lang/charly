require_relative "Helper.rb"
require_relative "Parser.rb"

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

    while !@structure_finished
      @structure_finished = true
      optimize_structure program
    end

    while !@grouping_finished
      @grouping_finished = true
      # optimize_group program
    end

    program
  end

  # Optimize the structure of a node and all children
  def optimize_structure(node)

    # Backup the parent
    parent_save = node.parent

    # Call the entry handler
    node = optimize_structure_entry node

    # Return if the node returned NIL
    if node == NIL
      return NIL
    end

    # Correct the parent pointer
    node.parent = parent_save

    # Optimize all children and remove nil values afterwards
    node.children.collect! do |child|
      optimize_structure child
    end
    node.children = node.children.compact
    node
  end

  # Optimize the structure of a node
  def optimize_structure_entry(node)

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

    # Remove LEFT_PAREN and RIGHT_PAREN nodes
    if node.is LeftParenLiteral, RightParenLiteral
      @structure_finished = false
      return NIL
    end

    # Group arithmetic operations together
    if node.is(Expression) && node.children.length == 3
      child1 = node.children[0]
      child2 = node.children[1]
      child3 = node.children[2]

      # Check if child 2 is an operator
      if child2.is OperatorLiteral

        # Typecheck child1 and child2
        if child1.is(NumericalLiteral, IdentifierLiteral, Expression) &&
          child3.is(NumericalLiteral, IdentifierLiteral, Expression)

          puts "found pattern"
        end
      end
    end

    node
  end
end
