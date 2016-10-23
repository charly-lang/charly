require "../../helper.cr"
require "../../file.cr"
require "../../interpreter/stack/stack.cr"

module Charly::Parser::AST
  abstract class ASTNode
    property children : Array(ASTNode)

    def initialize
      @children = [] of ASTNode
    end

    # Appends *node* to the children of this node
    def <<(node)
      @children << node
    end

    def size
      @children.size
    end

    def [](index)
      @children[index]
    end

    # Correct the parent pointers of all children
    def children=(new_children)
      @children = new_children
    end

    # Render the current node
    def to_s(io)
      io << "#{self.class.name}"

      if @children.size > 0
        io << " - #{@children.size} children"
      end

      io << "\n"

      children.each do |child|
        lines = child.to_s.each_line.each
        lines.each do |line|
          if !['┣', '┃'].includes?(line[0])
            io << line.indent(1, "┣╸")
          elsif line.size > 0
            io << line.indent(1, "┃ ")
          end
        end
      end
    end
  end

  macro ast_node(name, parent, properties)
    class {{name}} < {{parent}}
      {% for prop in properties %}
        property {{prop}}
      {% end %}

      {% if properties.size == 0 %}
        def initialize(@children : Array(ASTNode))
        end
      {% else %}
        def initialize({{properties.argify}})
          {% for prop in properties %}
            @{{prop.var}} = {{prop.var}}
          {% end %}
        end
      {% end %}
    end
  end
end

ast_node Empty, ASTNode, []
ast_node Program, ASTNode, []
ast_node Block, ASTNode, []
ast_node Statement, ASTNode, []

ast_node IfStatement, ASTNode, [
  test : ASTNode,
  consequent : Block,
  alternate : ASTNode
]

ast_node WhileStatement, ASTNode, [
  test : ASTNode,
  consequent : Block
]

ast_node Group, ASTNode, []
ast_node Expression, ASTNode, []

ast_node UnaryExpression, ASTNode, [
  operator : ASTNode,
  right : ASTNode
]

ast_node BinaryExpression, ASTNode, [
  operator : ASTNode,
  left : ASTNode,
  right : ASTNode
]

ast_node ComparisonExpression, ASTNode, [
  operator : ASTNode,
  left : ASTNode,
  right : ASTNode
]

ast_node LogicalExpression, ASTNode, [
  operator : ASTNode,
  left : ASTNode,
  right : ASTNode
]

ast_node VariableDeclaration, ASTNode, [
  identifier : Identifier
]

ast_node VariableInitialisation, ASTNode, [
  identifier : Identifier,
  expression : ASTNode
]

ast_node ConstantInitialisation, ASTNode, [
  identifier : Identifier,
  expression : ASTNode
]

ast_node VariableAssignment, ASTNode, [
  identifier : ASTNode,
  expression : ASTNode
]

ast_node ClassLiteral, ASTNode, [
  block : Block
]

ast_node CallExpression, ASTNode, [
  identifier : ASTNode,
  argumentlist : ExpressionList
]

ast_node MemberExpression, ASTNode, [
  identifier : ASTNode,
  member : Identifier
]

ast_node IndexExpression, ASTNode, [
  identifier : ASTNode,
  member : ASTNode
]

ast_node ExpressionList, ASTNode, []
ast_node IdentifierList, ASTNode, []

ast_node ReturnStatement, ASTNode, [
  expression : ASTNode
]

ast_node ThrowStatement, ASTNode, [
  expression : ASTNode
]

ast_node BreakStatement, ASTNode, []

ast_node TryCatchStatement, ASTNode, [
  try_block : Block,
  exception_name : Identifier,
  catch_block : Block
]

ast_node NullLiteral, ASTNode, []
ast_node NANLiteral, ASTNode, []
ast_node IdentifierLiteral, ASTNode, [
  name : String
]

ast_node StringLiteral, ASTNode, [
  value : String
]

ast_node NumericLiteral, ASTNode, [
  value : Float64
]

ast_node KeywordLiteral, ASTNode, [
  name : String
]

ast_node BooleanLiteral, ASTNode, [
  value : Bool
]

ast_node ArrayLiteral, ASTNode, []

ast_node FunctionLiteral, ASTNode, [
  argumentlist : IdentifierList,
  block : Block
]

ast_node ContainerLiteral, ASTNode, [
  block : Block
]

ast_node LeftParenLiteral, ASTNode, []
ast_node RightParenLiteral, ASTNode, []
ast_node LeftCurlyLiteral, ASTNode, []
ast_node RightCurlyLiteral, ASTNode, []
ast_node LeftBracketLiteral, ASTNode, []
ast_node RightBracketLiteral, ASTNode, []

# Punctuators
ast_node SemicolonLiteral, ASTNode, []
ast_node CommaLiteral, ASTNode, []
ast_node PointLiteral, ASTNode, []

# Operators
ast_node AssignmentOperator, ASTNode, []
ast_node PlusOperator, ASTNode, []
ast_node MinusOperator, ASTNode, []
ast_node MultOperator, ASTNode, []
ast_node DivdOperator, ASTNode, []
ast_node ModOperator, ASTNode, []
ast_node PowOperator, ASTNode, []

# Comparisons
ast_node LessOperator, ASTNode, []
ast_node GreaterOperator, ASTNode, []
ast_node LessEqualOperator, ASTNode, []
ast_node GreaterEqualOperator, ASTNode, []
ast_node EqualOperator, ASTNode, []
ast_node NotOperator, ASTNode, []

# Logical Operators
ast_node ANDOperator, ASTNode, []
ast_node OROperator, ASTNode, []
