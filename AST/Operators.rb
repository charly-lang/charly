require_relative "ASTNode.rb"
require_relative "Grammar.rb"

# Operator superclass
class OperatorLiteral < Terminal
end

# A plus operator
class PlusOperator < OperatorLiteral
end

# A minus operator
class MinusOperator < OperatorLiteral
end

# A multiplication operator
class MultOperator < OperatorLiteral
end

# A division operator
class DivdOperator < OperatorLiteral
end

# An assignment operator
class AssignmentOperator < OperatorLiteral
end
