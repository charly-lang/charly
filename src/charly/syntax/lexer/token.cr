# The different types of tokens
@[Flags]
enum TokenType

  # Literals
  Numeric
  Identifier

  # Operators
  Plus
  Minus
  Mult
  Divd
  Mod
  Pow

  # Structural
  LeftParen, RightParen
  Semicolon

  # Whitespace
  Whitespace
  Newline

  # Internal
  EOF
  Unknown
end

# Token
# A single token with a type and a value
class Token
  property type : TokenType
  property value : String

  def initialize(@type = TokenType::Unknown, @value = "")
  end

  def to_s(io)
    if @value.size == 0
      io << "#{@type}"
    else
      io << "#{@type}: '#{@value}'"
    end
  end
end
