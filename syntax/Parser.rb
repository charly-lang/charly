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
  def peek_term(token, string = "")
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

    # Skip whitespace and comments
    if string != ""
      @tokens[@next].token == token && @tokens[@next].value == string
    else
      @tokens[@next].token == token
    end
  end

  # Check if the next token is equal to *token*
  # Changes the @next pointer to point to the next token
  def term(token, string = "")
    match = peek_term(token, string)

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

      # If func is a boolean, return it
      if func.instance_of?(TrueClass) || func.instance_of?(FalseClass)
        match = func unless match
      end

      # Reset
      @next = save
      @node = backup

      # Create temporary node
      temp = Temporary.new NIL
      @node = temp

      # Try the production
      if func.is_a? Proc
        match = func.call unless match
      else
        match = method(func).call unless match
      end

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
    node_production(Block, Proc.new {
      found_at_least_one = false
      while !peek_term(:RIGHT_CURLY) && S()
        found_at_least_one = true unless found_at_least_one
      end
      found_at_least_one
    }, true)
  end

  def S
    node_production(Statement, Proc.new {
      if term(:KEYWORD, "let") && term(:IDENTIFIER)
        check_each([Proc.new {
          term(:ASSIGNMENT) && E() && term(:TERMINAL)

        }, Proc.new {
          term(:TERMINAL)

        }])
      end
    }, Proc.new {
      E() && term(:TERMINAL)

    }, Proc.new {
      I() && term(:TERMINAL)

    }, Proc.new {
      term(:KEYWORD, "while") &&
      term(:LEFT_PAREN) &&
      E() &&
      term(:RIGHT_PAREN) &&
      term(:LEFT_CURLY) &&
      B() &&
      term(:RIGHT_CURLY) &&
      term(:TERMINAL)

    })
  end

  def I
    node_production(IfStatementPrimitive, Proc.new {
      if term(:KEYWORD, "if") &&
          term(:LEFT_PAREN) &&
          E() &&
          term(:RIGHT_PAREN) &&
          term(:LEFT_CURLY) &&
          B() &&
          term(:RIGHT_CURLY)

        # Parse the else or else if clause
        check_each([Proc.new {
          if term(:KEYWORD, "else")
            check_each([Proc.new {
              term(:LEFT_CURLY) && B() && term(:RIGHT_CURLY)

            }, Proc.new {
              I()

            }, true])
          end
        }, true])
      end
    })
  end

  # Expression list
  def EL
    node_production(ExpressionList, Proc.new {
      if E()
        check_each([Proc.new {
          found_at_least_one = false

          # We are peeking before because we are expanding two different nodes
          while peek_term(:COMMA) && term(:COMMA) && E()
            found_at_least_one = true unless found_at_least_one
          end
          found_at_least_one
        }, true])
      end
    }, true)
  end


  # Argument List
  def AL
    node_production ArgumentList, :AL1, true
  end

  def AL1
    term(:IDENTIFIER) && ALPRIME()
  end

  def ALPRIME
    check_each([:ALP1, true])
  end

  def ALP1
    term(:COMMA) && term(:IDENTIFIER) && ALPRIME()
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
