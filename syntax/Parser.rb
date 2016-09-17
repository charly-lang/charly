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
    if ARGV.include?("--tokens") && file.filename != "prelude.charly"
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
    # Show the range in which parsing failed
    if @next < @tokens.length
      dlog "Couldn't parse whole file. Failed at: "
      dlog ""
      @tokens[@next - 5, 10].each_with_index do |token, index|
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
    if ARGV.include?("--ast") && file.filename != "prelude.charly"
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
      when :LEFT_BRACK
        @node << new(LeftBracketLiteral)
      when :RIGHT_BRACK
        @node << new(RightBracketLiteral)
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

  # Argument list
  def AL
    node_production(ArgumentList, Proc.new {
      if term(:IDENTIFIER)
        check_each([Proc.new {
          found_at_least_one = false

          # We are peeking before because we are expanding two different nodes
          while peek_term(:COMMA) && term(:COMMA) && term(:IDENTIFIER)
            found_at_least_one = true unless found_at_least_one
          end
          found_at_least_one
        }, true])
      end
    }, true)
  end

  # Expressions
  def E
    node_production(Expression, Proc.new {

      # Term
      if T()
        check_each([Proc.new {
          term(:MULT) && E()
        }, Proc.new {
          term(:DIVD) && E()
        }, Proc.new {
          term(:PLUS) && E()
        }, Proc.new {
          term(:MINUS) && E()
        }, Proc.new {
          term(:MODULUS) && E()
        }, Proc.new {
          term(:POW) && E()
        }, Proc.new {
          term(:GREATER) && E()
        }, Proc.new {
          term(:LESS) && E()
        }, Proc.new {
          term(:LESSEQ) && E()
        }, Proc.new {
          term(:GREATEREQ) && E()
        }, Proc.new {
          term(:EQ) && E()
        }, Proc.new {
          term(:NOTEQ) && E()
        }])
      end
    }, Proc.new {

      # Parse assignments
      matched = check_each([Proc.new {
        CE()
      }, Proc.new {
        term(:IDENTIFIER)
      }])

      if matched
        term(:ASSIGNMENT) && E()
      end
    }, Proc.new {
      check_each([Proc.new {
        T()
      }, Proc.new {
        F()
      }])
    })
  end

  # Call Expressions
  def CE
    node_production(CallExpressionNode, Proc.new {
      matched = check_each([Proc.new {
        term(:IDENTIFIER)
      }, Proc.new {
        F()
      }])

      if matched
        term(:LEFT_PAREN) && EL() && term(:RIGHT_PAREN)
      end
    })
  end

  # Function literal
  def F
    node_production(Expression, Proc.new {
      term(:KEYWORD, "func") &&
      term(:IDENTIFIER) &&
      term(:LEFT_PAREN) &&
      AL() &&
      term(:RIGHT_PAREN) &&
      term(:LEFT_CURLY) &&
      B() &&
      term(:RIGHT_CURLY)
    })
  end

  # Arrays
  def A
    node_production(ArrayLiteral, Proc.new {
      term(:LEFT_BRACK) &&
      EL() &&
      term(:RIGHT_BRACK)
    })
  end

  # Terms
  def T
    node_production(Expression, Proc.new {
      term(:LEFT_PAREN) &&
      E() &&
      term(:RIGHT_PAREN)
    }, Proc.new {
      CE()
    }, Proc.new {
      check_each([Proc.new {
        term(:IDENTIFIER)
      }, Proc.new {
        term(:NUMERICAL)
      }, Proc.new {
        term(:STRING)
      }, Proc.new {
        term(:BOOLEAN)
      }, Proc.new {
        A()
      }])
    })
  end
end
