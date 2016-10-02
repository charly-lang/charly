# The different types of tokens
enum TokenType

  # Literals
  Numeric
  Identifier
  String
  Boolean
  Null
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

  def initialize(type = TokenType::Unknown, value = "", raw = "")
    @type = type
    @value = value
    @raw = raw
  end

  def to_s(io)
    if @value.size == 0
      io << "#{@type}"
    else
      io << "#{@type}: '#{@value}'"
    end
  end
end
