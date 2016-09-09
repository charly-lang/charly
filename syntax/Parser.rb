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

    # Output a list of tokens if the respective CLI flag was passed
    if ARGV.include? "--tokens"
      puts "--- found #{@tokens.length} tokens in #{file.filename} ---"
      puts @tokens
      puts "------"
    end

    # Generate the abstract syntax tree, starting with a statement
    dlog "Generating abstract syntax tree"
    B()

    # Disable the optimizer if the respective CLI flag was passed
    unless ARGV.include? "--noopt"
      optimizer = Optimizer.new
      optimizer.optimize_program @tree
    end

    # Output the abstract syntax tree if the CLI flag was passed
    if ARGV.include? "--ast"
      puts "--- #{file.filename} : Abstract Syntax Tree ---"
      puts @tree
      puts "------"
    end

    @tree
  end

  # Grammar Implementatino

  # Check if the next token is equal to *token*
  # Changes the @next pointer to point to the next token
  def term(token, string = "")

    if @next >= @tokens.size
      return false
    end

    # Skip whitespace and comments
    while @tokens[@next].token == :COMMENT ||
          @tokens[@next].token == :WHITESPACE do

      # We reached the end of the file
      if @next + 1 > (@tokens.length - 1)
        return false
      end

      # Increment the pointer
      @next += 1
    end

    if string != ""
      match = @tokens[@next].token == token && @tokens[@next].value == string
    else
      match = @tokens[@next].token == token
    end

    def new(node_type)
      node_type.new(@tokens[@next].value, @node)
    end

    if match
      case token
      when :NUMERICAL
        @node << new(NumericLiteral)
      when :IDENTIFIER
        @node << new(IdentifierLiteral)
      when :LEFT_PAREN
        @node << new(LeftParenLiteral)
      when :RIGHT_PAREN
        @node << new(RightParenLiteral)
      when :LEFT_CURLY
        @node << new(LeftCurlyLiteral)
      when :RIGHT_CURLY
        @node << new(RightCurlyLiteral)
      when :PLUS
        @node << new(PlusOperator)
      when :MINUS
        @node << new(MinusOperator)
      when :MULT
        @node << new(MultOperator)
      when :DIVD
        @node << new(DivdOperator)
      when :MODULUS
        @node << new(ModOperator)
      when :POW
        @node << new(PowOperator)
      when :TERMINAL
        @node << new(SemicolonLiteral)
      when :KEYWORD
        @node << new(KeywordLiteral)
      when :ASSIGNMENT
        @node << new(AssignmentOperator)
      when :COMMA
        @node << new(CommaLiteral)
      when :STRING
        @node << new(StringLiteral)
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
    node_production Block, :B1, :B2
  end

  def B1
    S() && BPRIME()
  end

  def B2
      true
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
    term(:KEYWORD, "let") && term(:IDENTIFIER) && term(:ASSIGNMENT) && E() && term(:TERMINAL)
  end

  def S2
    term(:KEYWORD, "let") && term(:IDENTIFIER) && term(:TERMINAL)
  end

  def S3
    E() && term(:TERMINAL)
  end




  # Argument list
  def EL
    node_production ExpressionList, :EL1
  end

  def EL1
    E() && ELPRIME()
  end

  def ELPRIME
    check_each([:ELP1, :ELP2])
  end

  def ELP1
    term(:COMMA) && E() && ELPRIME()
  end
  def ELP2; true end



  def AL
    node_production ArgumentList, :AL1, :AL2
  end

  def AL1
    term(:IDENTIFIER) && ALPRIME()
  end

  def AL2
      true
  end

  def ALPRIME
    check_each([:ALP1, :ALP2])
  end

  def ALP1
    term(:COMMA) && term(:IDENTIFIER) && ALPRIME()
  end

  def ALP2
    true
  end



  def E
    node_production Expression, :E1, :E2, :E3, :E4, :E5, :E6, :E7, :E8, :E9, :E10, :E11
  end

  def E1
    term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN)
  end

  def E2
    term(:IDENTIFIER) && term(:LEFT_PAREN) && EL() && term(:RIGHT_PAREN)
  end

  def E3
    term(:KEYWORD, "func") && term(:IDENTIFIER) && term(:LEFT_PAREN) && AL() && term(:RIGHT_PAREN) && term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY)
  end

  def E4
    T() && term(:MULT) && E()
  end

  def E5
    T() && term(:DIVD) && E()
  end

  def E6
    T() && term(:PLUS) && E()
  end

  def E7
    T() && term(:MINUS) && E()
  end

  def E8
    T() && term(:MODULUS) && E()
  end

  def E9
    T() && term(:POW) && E()
  end

  def E10
    term(:IDENTIFIER) && term(:ASSIGNMENT) && E()
  end

  def E11
    T()
  end


  def T
    node_production Expression, :T1, :T2, :T3, :T4
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
