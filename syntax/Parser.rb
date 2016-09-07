require_relative "Lexer.rb"
require_relative "../misc/Helper.rb"
require_relative "Optimizer.rb"
require_relative "AST.rb"

# Parser
class Parser

  attr_reader :tokens, :tree
  attr_accessor :debug

  # Initialize a new parser for a given file
  def initialize(file)
    @tree = Program.new file
    @node = @tree
    @next = 0
  end

  def self.parse(file)
    parser = self.new file
    parser.parse file
  end

  def parse(file)

    # Get a list of tokens from the lexer
    dlog "Starting lexical analysis"
    @tokens = Lexer.analyse file
    @next = 0

    # Generate the abstract syntax tree, starting with a statement
    dlog "Generating abstract syntax tree"
    B()

    # Optimize the tree if wanted
    dlog "Optimizing program"
    optimizer = Optimizer.new
    optimizer.optimize_program @tree
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
        @node << NumericLiteral.new(@tokens[@next].value, @node)
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
      when :STRING
        @node << StringLiteral.new(@tokens[@next].value, @node)
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
    node_production Term, :T1, :T2, :T3, :T4
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

  def T4
    term(:STRING)
  end
end
