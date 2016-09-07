require_relative "ASTNode.rb"

# Contains a program
class Program < ASTNode
  attr_reader :filename

  def initialize(filename)
    super(self)
    @filename = filename
  end
end

# Contains a block
class Block < ASTNode
end

# Temporary node used while parsing
# Allows to quickly throw away failed parsed nodes
class Temporary < ASTNode
end
