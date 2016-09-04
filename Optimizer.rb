require_relative "Helper.rb"
require_relative "Parser.rb"

# Optimizes a program to be more efficient
# Doesn't always produce the "perfect" program
class Optimizer

  def initialize
    @finished = false
  end

  # Optimize a program
  def optimize_program(program)
    if !program.instance_of? Program
      raise "Not a Program instance"
    end

    while !@finished
      @finished = true
      optimize program
    end

    program
  end

  # Optimize a single node in the program
  def optimize(node)

    # Backup the parent
    parent_save = node.parent

    # Call the entry handler
    node = entry node

    # Return if the node returned NIL
    if node == NIL
      return NIL
    end

    # Correct the parent pointer
    node.parent = parent_save

    # Optimize all children and remove nil values afterwards
    node.children.collect! do |child|
      optimize child
    end
    node.children = node.children.compact

    # Call the leave handler
    node = leave node

    # Correct the parent pointer
    node.parent = parent_save

    # Return
    node
  end

  # Called right after the optimizer enters a node
  def entry(node)

    # Structure nodes that only have 1 terminal child,
    # should be replaced by that child
    if node.instance_of? Term
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Terminal
          @finished = false
          return child
        end
      end
    end

    # Expression nodes that only have 1 terminal child,
    # should be replaced by that child
    if node.instance_of? Expression
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Terminal
          @finished = false
          return child
        end
      end
    end

    # Expression nodes that only have 1 Expression child,
    # should be replaced by that child
    if node.instance_of? Expression
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Expression
          @finished = false
          return child
        end
      end
    end

    # Structure nodes that only have 1 Expression child,
    # should be replaced by that child
    if node.instance_of? Term
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Expression
          @finished = false
          return child
        end
      end
    end

    # Remove LEFT_PAREN and RIGHT_PAREN nodes
    if node.instance_of? Terminal
      if node.token == :LEFT_PAREN || node.token == :RIGHT_PAREN
        @finished = false
        return NIL
      end
    end

    node
  end

  # Called just before the optimizer leaves a node
  def leave(node)
    node
  end
end
