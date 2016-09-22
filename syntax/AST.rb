class ASTNode
  attr_accessor :children, :parent

  # Debugging
  attr_accessor :build_time

  def initialize(parent)
    @children = []
    @parent = parent
  end

  def <<(item)
    @children << item
    self
  end

  def is(*types)
    match = false
    types.each do |type|
      if !match
        match = self.kind_of? type
      end
    end
    match
  end

  def is_exact(*types)
    match = false
    types.each do |type|
      if !match
        match = self.instance_of? type
      end
    end
    match
  end

  def meta
    ""
  end

  def to_s(depth = -1)
    if is Terminal
      string = "#: #{self.class.name}"
    else
      string = "#: #{self.class.name} - BT: #{build_time} ms"
    end

    if meta.length > 0 && !ARGV.include?("--nometa")
      string += " - #{meta}"
    end

    string += "\n"

    if depth > 0 || depth < 0
      children.each do |child|
        lines = child.to_s(depth - 1).each_line.entries
        lines.each {|line|
          if line[0] == "#"
            if children.length == 1 && child.children.length < 2
              string += line.indent(1, "└╴")
            else
              string += line.indent(1, "├╴")
            end
          elsif line.length > 1
            string += line.indent(1, "│ ")
          end
        }
      end
    end
    string
  end

  def as_json(*a)
    if @children.length > 0
      {
        "name" => self.class.to_s,
        "children" => @children
      }
    else
      {
        "name" => self.class.to_s,
        "value" => @value,
      }
    end
  end

  def to_json(*a)
    as_json.to_json(*a)
  end
end

# Temporary node used while parsing and constructing tree nodes
# Allows to quickly throw away failed productions
class Temporary < ASTNode
end

# A block containing expressions and statements
class Block < ASTNode
  attr_accessor :parent_stack
end

# A single program with no parent nodes
class Program < Block
  attr_reader :file
  attr_accessor :should_execute

  def initialize(file)
    super(NIL)
    @file = file
    @should_execute = true
  end
end

# A statement is a language-specific construct
# For example, the IF-node would subclass Statement
class Statement < ASTNode; end

# Pre-grouping IfStatement (Needed until I write a smarter Parser)
class IfStatementPrimitive < Statement; end

# A single if statement
class IfStatement < Statement
  attr_accessor :test, :consequent, :alternate

  def initialize(test, consequent, alternate, parent)
    super(parent)
    @test = test
    @consequent = consequent
    @alternate = alternate
    @children = [@test, @consequent, @alternate]
  end
end

# A single while statement
class WhileStatement < Statement
  attr_accessor :test, :consequent

  def initialize(test, consequent, parent)
    super(parent)
    @test = test
    @consequent = consequent
    @children = [@test, @consequent]
  end
end

# A single expression, which can be nested indefinitely inside other
# expressions
class Expression < ASTNode
end

# A single binary expression, performing a calculation
class BinaryExpression < Expression
  attr_reader :operator, :left, :right

  def initialize(operator, left, right, parent)
    super(parent)
    @operator = operator
    @left = left
    @right = right
    @children = [@left, @operator, @right]
  end
end

# A single comparison expression
class ComparisonExpression < Expression
  attr_reader :operator, :left, :right

  def initialize(operator, left, right, parent)
    super(parent)
    @operator = operator
    @left = left
    @right = right
    @children = [@left, @operator, @right]
  end
end

# A variable decleration, not initialisation
#
# yes:
# let a;
# let myvar;
#
# no:
# let a = 2;
# let myvar = "hello";
class VariableDeclaration < Statement
  attr_reader :identifier

  def initialize(identifier, parent)
    super(parent)
    @identifier = identifier
    @children = [@identifier]
  end
end

# A variable initialisation, not decleration
#
# yes:
# let a = 2;
# let myvar = "hello";
#
# no:
# let a;
# let myvar;
class VariableInitialisation < Statement
  attr_reader :identifier, :expression

  def initialize(identifier, expression, parent)
    super(parent)
    @identifier = identifier
    @expression = expression
    @children = [@identifier, @expression]
  end
end

class VariableAssignment < Expression
  attr_reader :identifier, :expression

  def initialize(identifier, expression, parent)
    super(parent)
    @identifier = identifier
    @expression = expression
    @children = [@identifier, @expression]
  end
end

# A class literal
class ClassLiteralNode < Expression; end
class ClassLiteral < Expression
  attr_reader :identifier, :initialize, :block

  def initialize(identifier, initialize, block, parent)
    super(parent);
    @identifier = identifier
    @initialize = initialize
    @block = block
  end
end
class ClassDefinition < Expression
  attr_reader :classliteral

  def initialize(classliteral, parent)
    super(parent);
    @classliteral = classliteral
    @children = [classliteral]
  end
end

# A single function call expression
class CallExpressionNode < Expression; end
class CallExpression < Expression
  attr_reader :identifier, :argumentlist

  def initialize(identifier, argumentlist, parent)
    super(parent)
    @identifier = identifier
    @argumentlist = argumentlist
    @children = [@identifier, @argumentlist]
  end
end

# A single function definition
class FunctionDefinitionExpression < Expression
  attr_reader :function

  def initialize(function, parent)
    super(parent)
    @function = function
    @children = [@function]
  end
end

# A list of expressions seperated by commas
class ExpressionList < ASTNode
  def each
    @children.each do |child|
      yield child
    end
  end
end

# A list of identifiers seperated by commas
class ArgumentList < ASTNode
end

# A write to an index in an array
class ArrayIndexWrite < Expression
  attr_accessor :identifier, :location, :expression

  def initialize(identifier, location, expression, parent)
    super(parent);
    @identifier = identifier
    @location = location
    @expression = expression
    @children = [identifier, location, expression]
  end
end

# A terminal node mapping directly to a token
# returned by the lexical analysis
class Terminal < ASTNode
  attr_accessor :value

  def initialize(value, parent)
    super(parent)
    @value = value
  end

  def meta
    "#{@value}"
  end
end

class LiteralValue < Terminal; end;

# A single numeric literal
class NumericLiteral < LiteralValue; end
class NullLiteral < LiteralValue; end
class IdentifierLiteral < LiteralValue; end
class StringLiteral < LiteralValue; end
class KeywordLiteral < LiteralValue; end
class BooleanLiteral < LiteralValue; end
class ArrayLiteral < Expression; end
class FunctionLiteral < Expression
    attr_reader :identifier, :argumentlist, :block

    def initialize(identifier, argumentlist, block, parent)
        super(parent)
        @identifier = identifier
        @argumentlist = argumentlist
        @block = block
        @children = [@identifier, @argumentlist, @block]
    end
end

# Parantheses
class LeftParenLiteral < Terminal; end
class RightParenLiteral < Terminal; end
class LeftCurlyLiteral < Terminal; end
class RightCurlyLiteral < Terminal; end
class LeftBracketLiteral < Terminal; end
class RightBracketLiteral < Terminal; end

# Semicolon and comma
class SemicolonLiteral < Terminal; end
class CommaLiteral < Terminal; end

# Arithmetic operators
class BinaryOperatorLiteral < Terminal; end
  class PlusOperator < BinaryOperatorLiteral; end
  class MinusOperator < BinaryOperatorLiteral; end
  class MultOperator < BinaryOperatorLiteral; end
  class DivdOperator < BinaryOperatorLiteral; end
  class ModOperator < BinaryOperatorLiteral; end
  class PowOperator < BinaryOperatorLiteral; end

# Comparisons
class ComparisonOperatorLiteral < Terminal; end
  class SmallerOperator < ComparisonOperatorLiteral; end
  class GreaterOperator < ComparisonOperatorLiteral; end
  class SmallerEqualOperator < ComparisonOperatorLiteral; end
  class GreaterEqualOperator < ComparisonOperatorLiteral; end
  class EqualOperator < ComparisonOperatorLiteral; end
  class NotEqualOperator < ComparisonOperatorLiteral; end

# Other operators
class AssignmentOperator < Terminal; end
