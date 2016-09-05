require_relative "ASTNode.rb"
require_relative "Grammar.rb"

# A single binary expression, performing a calculation
class BinaryExpression < Expression
  attr_reader :operator, :left, :right

  def initialize(operator, left, right, parent)
    super(parent)
    @operator = operator
    @left = left
    @right = right
  end

  def children_string
    [@left, @operator, @right]
  end
end

# Variable Assignments
class VariableAssignment < Expression
  attr_reader :identifier, :expression

  def initialize(identifier, expression, parent)
    super(parent)
    @identifier = identifier
    @expression = expression
  end

  def children_string
    [@identifier, @expression]
  end
end
