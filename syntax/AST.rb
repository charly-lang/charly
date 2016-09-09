class ASTNode
  attr_accessor :children, :parent, :scope_id

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

  def meta
    ""
  end

  def to_s
    string = "#: #{self.class.name} - #{@scope_id}"

    if meta.length > 0
      string += " - #{meta}"
    end

    string += "\n"

    children.each do |child|
      lines = child.to_s.each_line.entries
      lines.each {|line|
        if line[0] == "#"
          if children.length == 1 && child.children.length < 2
            string += line.indent(1, "└╴");
          else
            string += line.indent(1, "├╴")
          end
        elsif line.length > 1
          string += line.indent(1, "│ ")
        end
      }
    end
    string
  end
end

# Temporary node used while parsing and constructing tree nodes
# Allows to quickly throw away failed productions
class Temporary < ASTNode
end

# A block containing expressions and statements
class Block < ASTNode
end

# A single program with no parent nodes
class Program < Block
  attr_reader :file

  def initialize(file)
    super(NIL)
    @file = file
  end
end

# A statement is a language-specific construct
# For example, the IF-node would subclass Statement
class Statement < ASTNode
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

# A single function call expression
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

# A single function literal
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
  def each
    @children.each do |child|
      yield child
    end
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

# Parantheses
class LeftParenLiteral < Terminal; end
class RightParenLiteral < Terminal; end
class LeftCurlyLiteral < Terminal; end
class RightCurlyLiteral < Terminal; end

# Semicolon and comma
class SemicolonLiteral < Terminal; end
class CommaLiteral < Terminal; end

# A single numeric literal
#
# 2
# 2.5
# -2
# -2.5
class NumericLiteral < Terminal
end

# A single identifier
#
# a
# abc
# myvar
class IdentifierLiteral < Terminal
end

# A single string
#
# "test"
# "wassuuup"
# ""
# "my name is ""leonard"" schuetz"
class StringLiteral < Terminal
end

# A single keyword
class KeywordLiteral < Terminal
end

# Arithmetic operators
class BinaryOperatorLiteral < Terminal; end
  class PlusOperator < BinaryOperatorLiteral; end
  class MinusOperator < BinaryOperatorLiteral; end
  class MultOperator < BinaryOperatorLiteral; end
  class DivdOperator < BinaryOperatorLiteral; end
  class ModOperator < BinaryOperatorLiteral; end
  class PowOperator < BinaryOperatorLiteral; end

# Other operators
class AssignmentOperator < Terminal; end
