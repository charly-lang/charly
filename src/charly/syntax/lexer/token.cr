require "../../file.cr"

# The different types of tokens
enum TokenType

  # Literals
  Numeric
  Identifier
  String
  Boolean
  Null
  NAN
  Keyword

  # Arithmetic Operators
  Plus
  Minus
  Mult
  Divd
  Mod
  Pow

  # Misc Operators
  Assignment

  # Comparison operators
  Equal
  Not
  Less
  Greater
  LessEqual
  GreaterEqual

  # Logic Operators
  AND
  OR

  # Structural
  LeftParen, RightParen
  LeftCurly, RightCurly
  LeftBracket, RightBracket
  Semicolon
  Comma
  Point
  Comment

  # Whitespace
  Whitespace
  Newline

  # Internal
  EOF
  Unknown
end

# A single token with a type and a value
class Token
  property type : TokenType
  property value : String
  property raw : String
  property touched : Bool
  property location : Location

  def initialize(type = TokenType::Unknown, value = "", raw = "")
    @type = type
    @value = value
    @raw = raw
    @touched = false
    @location = Location.new
  end

  def to_s(io)
    io << "#{@location}"
    io << " │ "

    if @value.size == 0
      io << "#{@type.to_s.ljust(12, ' ')}"
      io << "│"
    else
      io << "#{@type.to_s.ljust(12, ' ')}"
      io << "│ "
      io << "#{@raw}"
    end
  end
end
