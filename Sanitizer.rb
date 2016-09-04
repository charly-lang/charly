require_relative "Helper.rb"
require_relative "Parser.rb"

class Sanitizer

  def initialize
    @sanitized = true
  end

  def sanitize_program(tree)
    if !tree.instance_of? Program
      raise "Not a Program instance"
    end

    while @sanitized
      @sanitized = false
      sanitize tree
    end
  end

  def sanitize(node)
    node = entry node

    # Return if the node returned NIL
    if node == NIL
      return NIL
    end

    node.children.collect! do |child|
      sanitize child
    end
    node.children = node.children.compact
    node = leave node
  end

  # Called right after the sanitizer enters a node
  def entry(node)

    # Structure nodes that only have 1 terminal child,
    # should be replaced by that child
    if node.instance_of? Structure
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Terminal
          @sanitized = true
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
          @sanitized = true
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
          @sanitized = true
          return child
        end
      end
    end

    # Structure nodes that only have 1 Expression child,
    # should be replaced by that child
    if node.instance_of? Structure
      if node.children.length == 1
        child = node.children[0]
        if child.instance_of? Expression
          @sanitized = true
          return child
        end
      end
    end

    # Remove LEFT_PAREN and RIGHT_PAREN nodes
    if node.instance_of? Terminal
      if node.token == :LEFT_PAREN || node.token == :RIGHT_PAREN
        @sanitized = true
        return NIL
      end
    end

    node
  end

  # Called just before the sanitizer leaves a node
  def leave(node)
    node
  end
end
