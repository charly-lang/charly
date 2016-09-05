require_relative "Lexer.rb"
require_relative "Helper.rb"
require_relative "Optimizer.rb"

class Parser

  attr_reader :tokens, :tree
  attr_accessor :debug, :output_intermediate_tree

  def initialize
    @tree = Program.new
    @node = @tree
    @next = NIL
    @debug = false
    @output_intermediate_tree = false
  end

  def parse(input)

    # Get a list of tokens from the lexer
    dlog "Starting lexical analysis"
    lexer = Lexer.new
    @tokens = lexer.analyse input
    @next = 0
    dlog "Finished lexical analysis"

    # Generate the abstract syntax tree, starting with a statement
    dlog "Generating abstract syntax tree"
    B()
    dlog "Finished generating abstract syntax tree"

    if @output_intermediate_tree
      puts "------"
      puts @tree
      puts "------"
    end

    # Optimize the tree if wanted
    dlog "Optimizing program"
    optimizer = Optimizer.new
    optimizer.optimize_program @tree
    dlog "Finished optimizing program"

    @tree
  end

  # Grammar Implementatino

  # Check if the next token is equal to *token*
  # Changes the @next pointer to point to the next token
  def term(token)

    if @next >= @tokens.size
      return false
    end

    # Skip whitespace and comments
    while @tokens[@next].token == :COMMENT ||
          @tokens[@next].token == :WHITESPACE do
      @next += 1
    end

    match = @tokens[@next].token == token

    if match
      case token
      when :NUMERICAL
        @node << NumericalLiteral.new(@tokens[@next].value, @node)
      when :IDENTIFIER
        @node << IdentifierLiteral.new(@tokens[@next].value, @node)
      when :LEFT_PAREN
        @node << LeftParenLiteral.new(@tokens[@next].value, @node)
      when :RIGHT_PAREN
        @node << RightParenLiteral.new(@tokens[@next].value, @node)
      when :PLUS
        @node << PlusOperator.new(@tokens[@next].value, @node)
      when :MINUS
        @node << MinusOperator.new(@tokens[@next].value, @node)
      when :MULT
        @node << MultOperator.new(@tokens[@next].value, @node)
      when :DIVD
        @node << DivdOperator.new(@tokens[@next].value, @node)
      when :TERMINAL
        @node << SemicolonLiteral.new(@tokens[@next].value, @node)
      when :KEYWORD
        @node << KeywordLiteral.new(@tokens[@next].value, @node)
      when :ASSIGNMENT
        @node << AssignmentOperator.new(@tokens[@next].value, @node)
      when :COMMA
        @node << CommaLiteral.new(@tokens[@next].value, @node)
      end
    end

    @next += 1

    match
  end

  def check_each(list)
    save = @next
    backup = @node
    match = false
    list.each do |func|

      # Skip if a production has already matched
      next if match

      # Reset
      @next = save
      @node = backup

      # Create temporary node
      temp = Temporary.new NIL
      @node = temp

      # Try the production
      match = method(func).call unless match

      # Flush the temporary children to the real node
      if match
        @node = backup
        temp.children.each do |child|
          @node << child
        end
      end
    end
    match
  end

  def node_production(node_class, *productions)
    save = @node
    @node = node_class.new @node
    match = check_each(productions)
    save << @node if match
    @node = save
    match
  end

  def B
    node_production Block, :B1
  end

  def B1
    S() && BPRIME()
  end

  # Fixes a left-recursion problem
  # with multiple statements written after each other
  def BPRIME
    check_each([:BP1, :BP2])
  end

  def BP1
    S() && BPRIME()
  end
  def BP2; true end

  def S
    node_production Statement, :S1, :S2, :S3
  end

  def S1
    term(:KEYWORD) && term(:IDENTIFIER) && term(:ASSIGNMENT) && E() && term(:TERMINAL)
  end

  def S2
    term(:IDENTIFIER) && term(:LEFT_PAREN) && A() && term(:RIGHT_PAREN) && term(:TERMINAL)
  end

  def S3
    E() && term(:TERMINAL)
  end

  # Argument list
  def A
    node_production ArgumentList, :A1
  end

  def A1
    E() && APRIME()
  end

  def APRIME
    check_each([:AP1, :AP2])
  end

  def AP1
    term(:COMMA) && E() && APRIME()
  end
  def AP2; true end

  def E
    node_production Expression, :E1, :E2, :E3, :E4, :E5
  end

  def E1
    T() && term(:MULT) && E()
  end

  def E2
    T() && term(:DIVD) && E()
  end

  def E3
    T() && term(:PLUS) && E()
  end

  def E4
    T() && term(:MINUS) && E()
  end

  def E5
    T()
  end

  def T
    node_production Term, :T1, :T2, :T3
  end

  def T1
    term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN)
  end

  def T2
    term(:NUMERICAL)
  end

  def T3
    term(:IDENTIFIER)
  end
end

class ASTNode
  attr_accessor :children, :parent

  def initialize(parent)
    @children = []
    @parent = parent
  end

  def <<(item)
    @children << item
    item
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

  def children_string
    @children
  end

  def to_s
    string = "#: #{self.class.name}"

    if meta.length > 0
      string += " - #{meta}"
    end

    string += "\n"

    children_string.each do |child|
      lines = child.to_s.each_line.entries
      lines.each {|line|
        if line[0] == "#"
          if children_string.length == 1 && child.children.length < 2
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

class Program < ASTNode
  def initialize
    super(self)
  end
end
class Temporary < ASTNode; end

# Grammar Nodes
class Block < ASTNode; end
class Statement < ASTNode; end
class Expression < ASTNode; end
class Term < ASTNode; end
class ArgumentList < ASTNode; end
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

# Numericals and identifier
class NumericalLiteral < Terminal; end
class IdentifierLiteral < Terminal; end
class KeywordLiteral < Terminal; end

# Structural
class LeftParenLiteral < Terminal; end
class RightParenLiteral < Terminal; end
class SemicolonLiteral < Terminal; end
class CommaLiteral < Terminal; end

# Operators
class OperatorLiteral < Terminal; end
class PlusOperator < OperatorLiteral; end
class MinusOperator < OperatorLiteral; end
class MultOperator < OperatorLiteral; end
class DivdOperator < OperatorLiteral; end
class AssignmentOperator < OperatorLiteral; end

# Expression statements
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

# Variable Assignments
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
