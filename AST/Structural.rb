require_relative "ASTNode.rb"
require_relative "Grammar.rb"

# A single left paren node
class LeftParenLiteral < Terminal
end

# A single right paren node
class RightParenLiteral < Terminal
end

# A single semicolon
class SemicolonLiteral < Terminal
end

# A single comma
class CommaLiteral < Terminal
end
