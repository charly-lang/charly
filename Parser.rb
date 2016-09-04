require_relative "Lexer.rb"
require_relative "Grammar.rb"
require_relative "Helper.rb"
require_relative "Optimizer.rb"

class Parser

  attr_reader :tokens, :tree
  attr_accessor :debug

  def initialize
    @grammar = Grammar.new
    @tree = Program.new
    @node = @tree
    @next = NIL
    @debug = false
  end

  def parse(input)
    st = Time.now.to_ms

    # Get a list of tokens from the lexer
    puts "|#{Time.now.to_ms - st}| Starting lexical analysis" if @debug
    lexer = Lexer.new
    @tokens = lexer.analyse input
    @next = 0
    puts "|#{Time.now.to_ms - st}| Finished lexical analysis" if @debug

    # Remove whitespace and comments from the tokens
    @tokens = @tokens.select {|token|
      token.token != :WHITESPACE && token.token != :COMMENT
    }

    # Generate the abstract syntax tree, starting with an expression
    puts "|#{Time.now.to_ms - st}| Generating abstract syntax tree" if @debug
    E()
    puts "|#{Time.now.to_ms - st}| Finished generating abstract syntax tree" if @debug

    # Optimize the tree if wanted
    puts "|#{Time.now.to_ms - st}| Optimizing program" if @debug
    optimizer = Optimizer.new
    optimizer.optimize_program @tree
    puts "|#{Time.now.to_ms - st}| Finished optimizing program" if @debug

    @tree
  end

  # Grammar Implementatino

  # Check if the next token is equal to *token*
  # Changes the @next pointer to point to the next token
  def term(token)

    if @next >= @tokens.size
      return false
    end

    @next += 1
    match = @tokens[@next - 1].token == token

    if match
      case token
      when :NUMERICAL
        @node << NumericalLiteral.new(@tokens[@next - 1].value, @node)
      when :IDENTIFIER
        @node << IdentifierLiteral.new(@tokens[@next - 1].value, @node)
      when :LEFT_PAREN
        @node << LeftParenLiteral.new(@tokens[@next - 1].value, @node)
      when :RIGHT_PAREN
        @node << RightParenLiteral.new(@tokens[@next - 1].value, @node)
      when :PLUS
        @node << PlusOperator.new(@tokens[@next - 1].value, @node)
      when :MINUS
        @node << MinusOperator.new(@tokens[@next - 1].value, @node)
      when :MULT
        @node << MultOperator.new(@tokens[@next - 1].value, @node)
      when :DIVD
        @node << DivdOperator.new(@tokens[@next - 1].value, @node)
      end
    end

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

  def dump

    # If we reached the program node
    if @parent == self || @parent == NIL
      puts self
    else
      @parent.dump
    end
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

  def to_s
    string = "#: #{self.class.name}"

    if meta.length > 0
      string += " - #{meta}"
    end

    string += "\n"

    @children.each do |child|
      lines = child.to_s.each_line.entries
      lines.each {|line|
        if line[0] == "#"
          if @children.length == 1 && child.children.length < 2
            string += line.indent(1, "└╴");
          else
            string += line.indent(1, "├╴")
          end
        else
          string += line.indent(1, "│  ")
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
    "#{@left}\n#{@operator}\n#{@right}"
  end
end
