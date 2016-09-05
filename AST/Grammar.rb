require_relative "ASTNode.rb"

# A statement terminated by a semicolon
class Statement < ASTNode
end

# An expression
class Expression < ASTNode
end

# A Term
class Term < ASTNode
end

# A list of expressions that can be passed to functions
class ArgumentList < ASTNode
end

# A terminal node mapping directly to a token
# returned by the lexical analysis
class Terminal < ASTNode
  attr_reader :value

  def initialize(value, parent)
    super(parent)
    @value = value
  end

  def meta
    "'#{@value}'"
  end
end
