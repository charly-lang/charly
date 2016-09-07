require_relative "ASTNode.rb"

# Contains a program
class Program < ASTNode
  def initialize
    super(self)
  end
end

# Contains a block
class Block < ASTNode
end

# Temporary node used while parsing
# Allows to quickly throw away failed parsed nodes
class Temporary < ASTNode
end
