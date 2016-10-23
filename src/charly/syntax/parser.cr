require "colorize"

require "./ast.cr"
require "./lexer.cr"

require "../exceptions.cr"
require "../interpreter/session.cr"

module Charly::Parser

  # Parses a list of tokens into a program
  class Parser
    include CharlyExceptions
    include AST

    property file : VirtualFile
    property session : Session

    property tokens : Array(Token)
    property token : Token
    property pos : Int32

    property tree : Program

    # Create a new parser from a virtualfile
    def initialize(@file, @session)
      @pos = 0
      @tokens = Lexer.new(file).all_tokens.select do |token|
        token.type != TokenType::Whitespace &&
        token.type != TokenType::Newline &&
        token.type != TokenType::Comment &&
        token.type != TokenType::EOF
      end
      @token = @tokens[0]

      # Print tokens
      if @session.flags.includes?("tokens") && @session.file == @file
        @tokens.each do |token|
          puts token
        end
      end

      # Initialize the tree
      @tree = Program.new
    end

    # Begin parsing
    def parse

      # If no interesting tokens were found in this file, don't try to parse it
      if @tokens.size == 0
        @tree << Block.new([] of ASTNode)
        return @tree
      end

      # Parse a block body
      @tree << block_body

      # Print the tree if the ast flag was set
      if @session.flags.includes?("ast") && @session.file == @file
        puts @tree
      end

      # Return the tree
      @tree
    end

    def has_next?
      @pos + 1 < @tokens.size
    end

    # Returns the next token
    def peek?
      if @pos + 1 >= @tokens.size
        unexpected_eof
      end

      @tokens[@pos + 1]
    end

    # Advances the pointer to the next token
    def advance?
      if @pos + 1 >= @tokens.size
        unexpected_eof
      end

      @pos += 1
      @token = @tokens[@pos]
      @tokens[@pos - 1]
    end

    # Throws a SyntaxError
    def unexpected_token
      raise SyntaxError.new(@token.location, "Unexpected token: #{@token.type}")
    end

    def unexpected_eof
      raise SyntaxError.new(@token.location, "Unexpected EOF")
    end

    def productions(*prods : Proc(ASTNode | Bool))

    end

    # Parses a block body surrounded by Curly Braces
    def block
      case @token.type
      when TokenType::LeftCurly
        body = block_body

        case advance?.type
        when TokenType::RightCurly
          return body
        else
          unexpected_token
        end
      else
        unexpected_token
      end
    end

    # Parses the body of a block
    def block_body
      exps = [] of ASTNode

      until @token.type == TokenType::RightCurly
        exps << statement
      end

      return Block.new(exps)
    end

    def statement
      case @token.type
    end

    def statement
      node_production(Statement, ->{
        match = false
        if token(TokenType::Keyword, "let") && token(TokenType::Identifier)
          match = check_each([->{
            token(TokenType::Assignment) && expression && skip_optional_token(TokenType::Semicolon)
          }, ->{
            skip_optional_token(TokenType::Semicolon)
          }])
        end
        match
      }, ->{
        token(TokenType::Keyword, "const") &&
        token(TokenType::Identifier) &&
        token(TokenType::Assignment) &&
        expression &&
        skip_optional_token(TokenType::Semicolon)
      }, ->{
        expression && skip_optional_token(TokenType::Semicolon)
      }, ->{
        if_statement && skip_optional_token(TokenType::Semicolon)
      }, ->{
        token(TokenType::Keyword, "while") &&
        check_each([->{
          skip_token(TokenType::LeftParen) &&
          expression &&
          skip_token(TokenType::RightParen)
        }, ->{
          expression
        }]) &&
        block &&
        skip_optional_token(TokenType::Semicolon)
      }, ->{
        try_catch_statement && skip_optional_token(TokenType::Semicolon)
      }, ->{
        return_statement && skip_optional_token(TokenType::Semicolon)
      }, ->{
        break_statement && skip_optional_token(TokenType::Semicolon)
      }, ->{
        throw_statement && skip_optional_token(TokenType::Semicolon)
      })
    end

    def return_statement
      node_production(ReturnStatement, ->{
        skip_token(TokenType::Keyword, "return") &&
        check_each([->{
          expression
        }, true])
      })
    end

    def break_statement
      node_production(BreakStatement, ->{
        skip_token(TokenType::Keyword, "break")
      })
    end

    def throw_statement
      node_production(ThrowStatement, ->{
        skip_token(TokenType::Keyword, "throw") &&
        check_each([->{
          expression
        }, true])
      })
    end

    def try_catch_statement
      node_production(TryCatchStatement, ->{
        skip_token(TokenType::Keyword, "try") &&
        block &&
        skip_token(TokenType::Keyword, "catch") &&
        skip_token(TokenType::LeftParen) &&
        optional_token(TokenType::Identifier) &&
        skip_token(TokenType::RightParen) &&
        block
      })
    end

    def if_statement
      node_production(IfStatement, ->{
        token(TokenType::Keyword, "if") &&
        check_each([->{
          skip_token(TokenType::LeftParen) &&
          expression &&
          skip_token(TokenType::RightParen)
        }, ->{
          expression
        }]) &&
        block &&
        check_each([->{
          token(TokenType::Keyword, "else") &&
          check_each([->{
            block
          }, ->{
            if_statement
          }, true])
        }, true])
      })
    end

    def expression_list
      node_production(ExpressionList, ->{
        match = false
        if expression
          match = check_each([->{
            found_at_least_one = false

            # We are peeking before because we are expanding two different nodes
            while peek_token(TokenType::Comma) && skip_token(TokenType::Comma) && expression
              found_at_least_one = true unless found_at_least_one
            end
            found_at_least_one
          }, true])
        end
        match
      }, true)
    end

    def identifier_list
      node_production(IdentifierList, ->{
        match = false
        if token(TokenType::Identifier)
          match = check_each([->{
            found_at_least_one = false

            # We are peeking before because we are expanding two different nodes
            while peek_token(TokenType::Comma) && skip_token(TokenType::Comma) && token(TokenType::Identifier)
              found_at_least_one = true unless found_at_least_one
            end
            found_at_least_one
          }, true])
        end
        match
      }, true)
    end

    def expression
      node_production(Expression, ->{
        if unary_expression
          check_each([->{
            token(TokenType::Plus) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Minus) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Mult) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Divd) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Mod) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Pow) && optional_token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::Greater) && expression
          }, ->{
            token(TokenType::Less) && expression
          }, ->{
            token(TokenType::LessEqual) && expression
          }, ->{
            token(TokenType::GreaterEqual) && expression
          }, ->{
            token(TokenType::Equal) && expression
          }, ->{
            token(TokenType::Not) && expression
          }, ->{
            token(TokenType::Assignment) && expression
          }, ->{
            token(TokenType::OR) && expression
          }, ->{
            token(TokenType::AND) && expression
          }])
          return true
        end
        return false
      })
    end

    def unary_expression
      node_production(UnaryExpression, ->{
        check_each([->{
          token(TokenType::Minus) && term
        }, ->{
          token(TokenType::Not) && unary_expression
        }, ->{
          term
        }])
      })
    end

    def term
      node_production(Expression, ->{
        token(TokenType::Numeric) && consume_postfix
      }, ->{
        token(TokenType::String) && consume_postfix
      }, ->{
        token(TokenType::Boolean) && consume_postfix
      }, ->{
        token(TokenType::Null) && consume_postfix
      }, ->{
        token(TokenType::NAN) && consume_postfix
      }, ->{
        token(TokenType::Identifier) && consume_postfix
      }, ->{
        group
      }, ->{
        array_literal && consume_postfix
      }, ->{
        function_literal && consume_postfix
      }, ->{
        class_literal && consume_postfix
      }, ->{
        container_literal && consume_postfix
      })
    end

    def term
      case @token.type

    end

    def group
      node_production(Group, ->{
        skip_token(TokenType::LeftParen) &&
        expression &&
        skip_token(TokenType::RightParen) && consume_postfix
      })
    end

    def function_literal
      node_production(FunctionLiteral, ->{
        token(TokenType::Keyword, "func") &&
        optional_token(TokenType::Identifier) &&
        skip_token(TokenType::LeftParen) &&
        identifier_list &&
        skip_token(TokenType::RightParen) &&
        block
      })
    end

    def array_literal
      node_production(ArrayLiteral, ->{
        skip_token(TokenType::LeftBracket) &&
        expression_list &&
        skip_token(TokenType::RightBracket)
      })
    end

    def class_literal
      node_production(ClassLiteral, ->{
        token(TokenType::Keyword, "class") &&
        optional_token(TokenType::Identifier) &&
        block
      })
    end

    def container_literal
      node_production(ContainerLiteral, ->{
        block
      })
    end

    # Alias for consume_call_expression && consume_member_expression
    def consume_postfix
      consume_call_expression && consume_member_expression && consume_index_expression
    end

    def consume_call_expression
      if peek_token(TokenType::LeftParen)
        node_save = @node
        children_save = @node.children.dup
        @node.children.clear
        @node = @node.parent

        match = node_production(CallExpression, ->{
          left_side = node_save.class.new(node_save.parent)
          left_side.children = children_save
          @node << left_side

          skip_token(TokenType::LeftParen) &&
          expression_list &&
          skip_token(TokenType::RightParen) &&
          consume_postfix
        })
        @node = node_save
        return match
      end
      true
    end

    def consume_member_expression
      if peek_token(TokenType::Point)
        node_save = @node
        children_save = @node.children.dup
        @node.children.clear
        @node = @node.parent

        match = node_production(MemberExpression, ->{
          left_side = node_save.class.new(node_save.parent)
          left_side.children = children_save
          @node << left_side

          skip_token(TokenType::Point) &&
          token(TokenType::Identifier) &&
          consume_postfix
        })
        @node = node_save
        return match
      end
      true
    end

    def consume_index_expression
      if peek_token(TokenType::LeftBracket)
        node_save = @node
        children_save = @node.children.dup
        @node.children.clear
        @node = @node.parent

        match = node_production(IndexExpression, ->{
          left_side = node_save.class.new(node_save.parent)
          left_side.children = children_save
          @node << left_side

          skip_token(TokenType::LeftBracket) &&
          expression_list &&
          skip_token(TokenType::RightBracket) &&
          consume_postfix
        })
        @node = node_save
        return match
      end
      true
    end
  end

end
