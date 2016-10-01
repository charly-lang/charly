require "./token.cr"
require "../../file.cr"

class Lexer
  property tokens : Array(Token)
  property input : VirtualFile
  property reader : Char::Reader
  property token

  def initialize(input)
    @input = input
    @token = Token.new
    @tokens = [] of Token
    @reader = Char::Reader.new @input.content
  end

  # Get the current_char
  def current_char
    @reader.current_char
  end

  # Get the next char
  def next_char
    @reader.next_char
  end

  # Go to the next char and set the token type
  def next_char(type)
    @token.type = type
    next_char
  end

  # Peek the next char
  def peek_char
    @reader.peek_next_char
  end

  # Resets the current token list and the current token
  def reset_token
    @token = Token.new
  end

  # Returns the contents of @reader.string
  # starting at *start* and stopping at @reader.pos - 1
  def string_range(start)
    @reader.string[start..@reader.pos - 1]
  end

  # Return all tokens in a string
  def all_tokens

    # Read as many tokens as we can
    while next_token.is_a? Token
      @tokens << @token

      # Break if we reached the end of the file
      if @token.type == TokenType::EOF
        break
      end
    end

    @tokens
  end

  # Return the next token in the file
  def next_token
    reset_token
    start = @reader.pos

    case current_char
    when ' ', '\t'
      consume_whitespace
    when '\n'
      consume_newline
    when ';'
      next_char TokenType::Semicolon
    when '0'..'9'
      consume_numeric
    when '+'
      next_char TokenType::Plus
    when '-'
      next_char TokenType::Minus
    when '/'
      next_char TokenType::Divd
    when '*'
      case next_char
      when '*'
        next_char TokenType::Pow
      else
        next_char TokenType::Mult
      end
    when '%'
      next_char TokenType::Mod
    when '('
      next_char TokenType::LeftParen
    when ')'
      next_char TokenType::RightParen
    when '\0'
      @token.type = TokenType::EOF
    else
      if ident_start(current_char)
        consume_ident
      else
        unknown_token
      end
    end

    @token
  end

  # Consumes whitespaces (space and tabs)
  def consume_whitespace
    @token.type = TokenType::Whitespace
    start = @reader.pos

    # Read as many whitespaces as possible
    while true
      char = next_char
      case char
      when ' ', '\t'
        # Nothing to do
      when '\\'
        if next_char == '\n'
          next_char
        else
          unknown_token
        end
      else
        break
      end
    end

    @token.value = string_range(start)
  end

  # Consumes newlines
  def consume_newline
    @token.type = TokenType::Newline
    start = @reader.pos

    while true
      char = next_char
      case char
      when '\n'
        # Nothing to do
      else
        break
      end
    end
  end

  # Consumes Integer and Float values
  def consume_numeric
    @token.type = TokenType::Numeric
    start = @reader.pos
    has_underscore = false
    is_float = false

    while true
      char = next_char
      if char.digit?
        # Nothing to do
      elsif char == '_'
        has_underscore = true
      else
        break
      end
    end

    number_value = string_range(start)
    @token.value = number_value.tr("_", "")
  end

  # Starts consuming an identifier
  def consume_ident
    start = @reader.pos
    while ident_part(current_char)
      next_char
    end
    @token.type = TokenType::Identifier
    @token.value = string_range(start)
  end

  # Returns true if *char* could be the start of an identifier
  def ident_start(char)
    char.alpha? || char == '_' || char.ord > 0x9F
  end

  # Returns true if *char* could be inside an identifier
  def ident_part(char)
    ident_start(char) || char.digit?
  end

  def unknown_token
    raise "Unknown token: #{current_char.inspect}"
  end
end
