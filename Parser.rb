require_relative "Lexer.rb"
require_relative "Grammar.rb"
require_relative "Helper.rb"
require_relative "Optimizer.rb"

class Parser

  attr_reader :tokens, :tree
  attr_accessor :debug, :output_intermediate_tree

  def initialize
    @grammar = Grammar.new
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

  def B
    save = @node
    @node = Block.new(@node)
    match = check_each([:B1, :B2])
    if match
      save << @node
    end
    @node = save
    match
  end

  def B1
    S() && S()
  end

  def B2
    S()
  end

  def S
    save = @node
    @node = Statement.new(@node)
    match = check_each([:S1, :S2])
    if match
      save << @node
    end
    @node = save
    match
  end

  def S1
    E() && term(:TERMINAL)
  end

  def S2
    E()
  end

  def E
    save = @node
    @node = Expression.new(@node)
    match = check_each([:E5, :E4, :E3, :E2, :E1])
    if match
      save << @node
    end
    @node = save
    match
  end

  def E1
    T()
  end

  def E2
    T() && term(:MULT) && E()
  end

  def E3
    T() && term(:DIVD) && E()
  end

  def E4
    T() && term(:PLUS) && E()
  end

  def E5
    T() && term(:MINUS) && E()
  end

  def T
    save = @node
    @node = Term.new(@node)
    match = check_each([:T3, :T2, :T1])
    if match
      save << @node
    end
    @node = save
    match
  end

  def T1
    term(:NUMERICAL)
  end

  def T2
    term(:IDENTIFIER)
  end

  def T3
    term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN)
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
class Terminal < ASTNode
  attr_reader :value

  def initialize(value, parent)
    super(parent)
    @value = value
  end

  def meta
    @value
  end
end

# Numericals and identifier
class NumericalLiteral < Terminal; end
class IdentifierLiteral < Terminal; end

# Structural
class LeftParenLiteral < Terminal; end
class RightParenLiteral < Terminal; end
class SemicolonLiteral < Terminal; end

# Operators
class OperatorLiteral < Terminal; end
class PlusOperator < OperatorLiteral; end
class MinusOperator < OperatorLiteral; end
class MultOperator < OperatorLiteral; end
class DivdOperator < OperatorLiteral; end

# Expression statements
class BinaryExpression < Expression
  attr_reader :operator, :left, :right

  def initialize(operator, left, right, parent)
    super(parent)
    @operator = operator
    @left = left
    @right = right
  end

  def meta
    ""
  end

  def children_string
    [@left, @operator, @right]
  end
end
