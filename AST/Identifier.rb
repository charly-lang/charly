require_relative "ASTNode.rb"
require_relative "Grammar.rb"

# Abstract class of all literals that can be evaluated as expressions
#
# NumericLiteral
# IdentifierLitearl
# StringLiteral
class ExpressionLiteral < Terminal
end

# A single numeric literal
#
# 2
# 2.5
# -2
# -2.5
class NumericLiteral < ExpressionLiteral
end

# A single identifier
#
# a
# abc
# myvar
class IdentifierLiteral < ExpressionLiteral
end

# A single string
#
# "test"
# "wassuuup"
# ""
# "my name is ""leonard"" schuetz"
class StringLiteral < ExpressionLiteral
end
