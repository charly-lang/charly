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
      @tree << parse_block_body(false)

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
        return unexpected_eof
      end

      @tokens[@pos + 1]
    end

    # Advances the pointer to the next token
    def advance
      if @pos + 1 >= @tokens.size
        return unexpected_eof
      end

      @pos += 1
      @token = @tokens[@pos]
    end

    # Throws a SyntaxError
    def unexpected_token
      raise SyntaxError.new(@token.location, "Unexpected token: #{@token.type}")
    end

    def unexpected_eof
      new_token = Token.new(TokenType::EOF)
      new_token.location = @token.location.dup
      new_token.location.column += new_token.location.length - 1
      new_token.location.length = 0

      @token = new_token
      @pos += 1

      return new_token
    end

    # Tries all productions
    # Catches SyntaxErrors
    # The first production that succeeds will be returned
    # If no production succeeded this will raise the last
    # SyntaxError thrown by the productions
    def try(*prods : Proc(ASTNode | Bool))
      start_pos = @pos
      result = nil

      prods.each_with_index do |prod, index|
        begin
          result = prod.call
          break
        rescue e : SyntaxError
          if index == prods.size - 1
            raise e
          end

          @pos = start_pos
          @token = @tokens[@pos]
        end
      end

      if result.is_a?(Nil)
        raise "fail"
      end

      return result
    end

    def optional(*prods)
      begin
        return try(*prods)
      rescue e : SyntaxError
        return Empty.new
      end
    end

    # Parses a block body surrounded by Curly Braces
    def parse_block
      case @token.type
      when TokenType::LeftCurly
        advance
        body = parse_block_body

        case @token.type
        when TokenType::RightCurly
          advance
          return body
        else
          unexpected_token
        end
      else
        unexpected_token
      end
    end

    # Parses the body of a block
    def parse_block_body(stop_on_curly = true)
      exps = [] of ASTNode

      if stop_on_curly
        until @token.type == TokenType::RightCurly
          exps << parse_statement
        end
      else
        until @token.type == TokenType::EOF
          exps << parse_statement
        end
      end

      return Block.new(exps)
    end

    def parse_statement
      case @token.type
      when TokenType::Keyword
        case @token.value
        when "let"
          case advance.type
          when TokenType::Identifier
            identifier = IdentifierLiteral.new(@token.value)

            case advance.type
            when TokenType::Semicolon
              advance
              return VariableDeclaration.new(identifier)
            when TokenType::Assignment
              advance
              value = parse_expression

              if @token.type == TokenType::Semicolon
                advance
              end

              return VariableInitialisation.new(identifier, value)
            else
              return VariableDeclaration.new(identifier)
            end
          else
            unexpected_token
          end
        when "const"
          case advance.type
          when TokenType::Identifier
            identifier = IdentifierLiteral.new(@token.value)

            case advance.type
            when TokenType::Assignment
              advance
              value = parse_expression

              if @token.type == TokenType::Semicolon
                advance
              end

              return ConstantInitialisation.new(identifier, value)
            else
              unexpected_token
            end
          else
            unexpected_token
          end
        when "if"
          return parse_if_statement
        when "while"
          return parse_while_statement
        when "try"
        when "return"
          advance
          return ReturnStatement.new(optional ->{parse_expression})
        when "break"
          advance
          return BreakStatement.new
        when "throw"
          advance
          return ThrowStatement.new(optional ->{parse_expression})
        end
      else
        begin
          expression = parse_expression
          case @token.type
          when TokenType::Semicolon
            advance
          end
          return expression
        rescue e : SyntaxError
          unexpected_token
        end
      end

      unexpected_token
    end

    def parse_if_statement

      unless @token.type == TokenType::Keyword && @token.value == "if"
        unexpected_token
      end

      case advance.type
      when TokenType::LeftParen
        advance

        test = parse_expression
        case @token.type
        when TokenType::RightParen
          advance
        else
          unexpected_token
        end
      else
        test = parse_expression
      end

      consequent = parse_block

      alternate = Empty.new
      if @token.type == TokenType::Keyword
        if @token.value == "else"
          advance

          case @token.type
          when TokenType::Keyword
            case @token.value
            when "if"
              alternate = parse_if_statement
            else
              unexpected_token
            end
          else
            alternate = parse_block
          end
        end
      end

      return IfStatement.new(test, consequent, alternate)
    end

    def parse_while_statement

      unless @token.type == TokenType::Keyword && @token.value == "while"
        unexpected_token
      end

      case advance.type
      when TokenType::LeftParen
        advance
        test = parse_expression

        case @token.type
        when TokenType::RightParen
          advance
        else
          unexpected_token
        end
      else
        test = parse_expression
      end

      consequent = parse_block
      return WhileStatement.new(test, consequent)
    end

    def parse_expression
      case @token.type
      when TokenType::Numeric
        node = NumericLiteral.new(@token.value.to_f64)
        advance
        return node
      else
        unexpected_token
      end
    end
  end
end
