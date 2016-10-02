require "../../helper.cr"
require "../../interpreter/stack.cr"

abstract class ASTNode
  property children : Array(ASTNode)
  property! parent : ASTNode
  property! value : String | Float64 | Bool

  def initialize(parent)
    @parent = parent
    @children = [] of ASTNode
  end

  # Appends *node* to the children of this node
  def <<(node)
    @children << node
    self
  end

  # Returns true if the current node matches at least one *types*
  def is(*types)
    match = false
    types.each do |type|
      if !match
        match = self.kind_of? type
      end
    end
    match
  end

  # Returns true if the current node is an instance of at least one *types*
  def is_exact(*types)
    match = false
    types.each do |type|
      if !match
        match = self.instance_of? type
      end
    end
    match
  end

  # Render the current node
  def to_s(io)
    io << "#: #{self.class.name}\n"

    children.each do |child|
      lines = child.to_s.each_line.each
      lines.each do |line|
        if line[0] == '#'
          io << line.indent(1, "├╴")
        elsif line.size > 0
          io << line.indent(1, "│ ")
        end
      end
    end
  end
end

# Temporary node used while parsing and constructing tree nodes
# Allows to quickly throw away failed productions
class Temporary < ASTNode
end

# A block containing statements
class Block < ASTNode
  property parent_stack : Stack?
end

# A single program with no parent nodes
class Program < Block
  property file : VirtualFile
  property should_execute : Bool

  def initialize(file)
    super(nil)
    @file = file
    @should_execute = true
  end
end

# A single statement in a block
class Statement < ASTNode
end

# An if statement
class IfStatement < Statement
  property test : ASTNode?
  property consequent : ASTNode?
  property alternate : ASTNode?
end

# While loops
class WhileStatement < Statement
  property test : ASTNode?
  property consequent : ASTNode?
end

# A single expression
class Expression < ASTNode
end

# A single unary expression
class UnaryExpression < Expression
  property operator : ASTNode?
  property right : ASTNode?
end

# A single binary expression
class BinaryExpression < Expression
  property operator : ASTNode?
  property left : ASTNode?
  property right : ASTNode?
end

# A single comparison expression
class ComparisonExpression < Expression
  property operator : ASTNode?
  property left : ASTNode?
  property right : ASTNode?
end

# A variable declaration
class VariableDeclaration < Statement
  property identifier : ASTNode?
end

# A variable initialisation
class VariableInitialisation < Statement
  property identifier : ASTNode?
  property expression : ASTNode?
end

# A variable assignment
class VariableAssignment < Expression
  property identifier : ASTNode?
  property expression : ASTNode?
end

# A class literal
class ClassLiteral < Expression
  property identifier : ASTNode?
  property constructor : ASTNode?
  property block : ASTNode?
end

# A class definition
class ClassDefinition < Statement
  property classliteral : ASTNode?
end

# A single call expression
class CallExpression < Expression
  property identifier : ASTNode?
  property argumentlist : ASTNode?
end

# A single member expression
class MemberExpression < Expression
  property identifier : ASTNode?
  property member : ASTNode?
end

# A single function definition
class FunctionDefinition < Expression
  property function : ASTNode?
end

# A list of expressions seperated by commas
class ExpressionList < ASTNode
  def each
    @children.each do |child|
      yield child
    end
  end
end

# A list of identifier seperated by commas
class IdentifierList < ASTNode
end

# A terminal node
class Terminal < ASTNode
end

# Literals
class LiteralValue < Terminal; end
class NullLiteral < Terminal; end
class IdentifierLiteral < Terminal; end
class StringLiteral < Terminal; end
class NumericLiteral < LiteralValue; end
class KeywordLiteral < LiteralValue; end
class BooleanLiteral < LiteralValue; end
class ArrayLiteral < Expression; end
class FunctionLiteral < Expression
  property identifier : ASTNode?
  property argumentlist : ASTNode?
  property block : ASTNode?
end

# Structure
class LeftParenLiteral < Terminal; end
class RightParenLiteral < Terminal; end
class LeftCurlyLiteral < Terminal; end
class RightCurlyLiteral < Terminal; end
class LeftBracketLiteral < Terminal; end
class RightBracketLiteral < Terminal; end

# Punctuators
class SemicolonLiteral < Terminal; end
class CommaLiteral < Terminal; end
class PointLiteral < Terminal; end

# Misc. Operators
class AssignmentOperator < Terminal; end

# Arithmetic operators
class OperatorLiteral < Terminal; end
  class PlusOperator < OperatorLiteral; end
  class MinusOperator < OperatorLiteral; end
  class MultOperator < OperatorLiteral; end
  class DivdOperator < OperatorLiteral; end
  class ModOperator < OperatorLiteral; end
  class PowOperator < OperatorLiteral; end

# Comparisons
class ComparisonOperatorLiteral < Terminal; end
  class LessOperator < ComparisonOperatorLiteral; end
  class GreaterOperator < ComparisonOperatorLiteral; end
  class LessEqualOperator < ComparisonOperatorLiteral; end
  class GreaterEqualOperator < ComparisonOperatorLiteral; end
  class EqualOperator < ComparisonOperatorLiteral; end
  class NotOperator < ComparisonOperatorLiteral; end
