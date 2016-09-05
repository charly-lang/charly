require_relative "ASTNode.rb"
require_relative "Grammar.rb"

# A single numeric literal
#
# 2
# 2.5
# -2
# -2.5
class NumericLiteral < Terminal
end

# A single identifier
#
# a
# abc
# myvar
class IdentifierLiteral < Terminal
end

# A keyword reserved by the language
#
# let
class KeywordLiteral < Terminal
end
