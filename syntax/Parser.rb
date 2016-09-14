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
    if ARGV.include?("--tokens") && file.filename != "prelude.txt"
      puts "--- found #{@tokens.length} tokens in #{yellow(file.filename)} ---"
      puts @tokens
      puts "------"
    end

    # If no tokens were found, return
    if @tokens.length == 0
      dlog "Aborting, no tokens found in: #{yellow(file.filename)}"
      @tree.should_execute = false
      return @tree
    end

    # Generate the abstract syntax tree, starting with a statement
    dlog "Generating abstract syntax tree"
    B()

    # Check if all tokens were parsed
    if @next < @tokens.length
      dlog "Couldn't parse whole file. Failed at: "
      dlog ""
      @tokens[@next - 1, 10].each do |token|
        dlog token
      end
      dlog ""
    end

    # Disable the optimizer if the respective CLI flag was passed
    unless ARGV.include? "--noopt"
      optimizer = Optimizer.new
      optimizer.optimize_program @tree
    end

    # Output the abstract syntax tree if the CLI flag was passed
    if ARGV.include?("--ast") && file.filename != "prelude.txt"
      puts "--- #{file.filename} : Abstract Syntax Tree ---"
      puts @tree
      puts "------"
    end

    @tree
  end

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
      when :BOOLEAN
        @node << new(BooleanLiteral)
      when :GREATER
        @node << new(GreaterOperator)
      when :LESS
        @node << new(SmallerOperator)
      when :GREATEREQ
        @node << new(GreaterEqualOperator)
      when :LESSEQ
        @node << new(SmallerEqualOperator)
      when :EQ
        @node << new(EqualOperator)
      when :NOTEQ
        @node << new(NotEqualOperator)
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
    start = Time.now.to_ms

    save = @node
    @node = node_class.new @node
    match = check_each(productions)
    if match
      @node.build_time = Time.now.to_ms - start
      save << @node
    end
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

  def BPRIME
    check_each([:BP1, :BP2])
  end

  def BP1
    S() && BPRIME()
  end
  def BP2; true end



  def S
    node_production Statement, :S1, :S2, :S3, :S4, :S5
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

  def S4
    I() && term(:TERMINAL)
  end

  def S5
    term(:KEYWORD, "while") && term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN) && term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY) && term(:TERMINAL)
  end



  def I
    node_production IfStatementPrimitive, :I1
  end

  def I1
    term(:KEYWORD, "if") && term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN) && term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY) && IP()
  end

  def IP
    check_each([:IP1, :IP2, :IP3])
  end

  def IP1
    term(:KEYWORD, "else") && term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY)
  end
  def IP2
    term(:KEYWORD, "else") && I()
  end
  def IP3
    true
  end



  # Expression list
  def EL
    node_production ExpressionList, :EL1, :EL2
  end

  def EL1
    E() && ELPRIME()
  end

  def EL2
    true
  end

  def ELPRIME
    check_each([:ELP1, :ELP2])
  end

  def ELP1
    term(:COMMA) && E() && ELPRIME()
  end
  def ELP2; true end



  # Argument List
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
    node_production Expression, :E1, :E2, :E3, :E4, :E5, :E6, :E7, :E8, :E9, :E10, :E11, :E12, :E13, :E14, :E15, :E16, :E17
  end

  def E1
    F() && term(:LEFT_PAREN) && EL() && term(:RIGHT_PAREN)
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

  def E6
    T() && term(:MODULUS) && E()
  end

  def E7
    T() && term(:POW) && E()
  end

  def E8
    T() && term(:GREATER) && E()
  end

  def E9
    T() && term(:LESS) && E()
  end

  def E10
    T() && term(:LESSEQ) && E()
  end

  def E11
    T() && term(:GREATEREQ) && E()
  end

  def E12
    T() && term(:EQ) && E()
  end

  def E13
    T() && term(:NOTEQ) && E()
  end

  def E14
    term(:IDENTIFIER) && term(:ASSIGNMENT) && E()
  end

  def E15
    term(:IDENTIFIER) && term(:LEFT_PAREN) && EL() && term(:RIGHT_PAREN)
  end

  def E16
    T()
  end

  def E17
    F()
  end


  def F
    node_production Expression, :F1
  end

  def F1
    term(:KEYWORD, "func") && term(:IDENTIFIER) && term(:LEFT_PAREN) && AL() && term(:RIGHT_PAREN) && term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY)
  end



  def T
    node_production Expression, :T1, :T2, :T3, :T4, :T5, :T6
  end

  def T1
    term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN)
  end

  def T2
    term(:IDENTIFIER) && term(:LEFT_PAREN) && EL() && term(:RIGHT_PAREN)
  end

  def T3
    term(:NUMERICAL)
  end

  def T4
    term(:IDENTIFIER)
  end

  def T5
    term(:STRING)
  end

  def T6
    term(:BOOLEAN)
  end
end
