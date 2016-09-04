require_relative "Lexer.rb"
require_relative "Grammar.rb"
require_relative "Helper.rb"
require_relative "Sanitizer.rb"

class Parser

  attr_reader :tokens
  attr_reader :tree

  def initialize
    @grammar = Grammar.new
    @tree = Program.new
    @node = @tree
    @next = NIL
  end

  def parse(input)

    # Get a list of tokens from the lexer
    lexer = Lexer.new
    @tokens = lexer.analyse input
    @next = 0

    # Remove whitespace from the tokens
    @tokens = @tokens.select {|token|
      token.token != :WHITESPACE && token.token != :COMMENT
    }

    # Generate the abstract syntax tree
    E()

    # Create a tree sanitizer
    sanitizer = Sanitizer.new
    sanitizer.sanitize_program @tree

    puts @tree
  end

  # Grammar Implementatino

  # Check if the next token is equal to *token*
  # Changes the @next pointer to point to the next token
  def term(token)

    if @next >= @tokens.size
      return false
    end

    @next += 1
    match = @tokens[@next - 1].token == token

    if match
      @node << Terminal.new(token, @tokens[@next - 1].value, @node)
    end

    match
  end

  def check_each(list)
    save = @next
    backup = @node
    match = false
    list.each do |func|

      # Skip if a production has already matched
      next if match

      # Reset
      @next = save
      @node = backup

      # Create temporary node
      temp = Temporary.new NIL
      @node = temp

      # Try the production
      match = method(func).call unless match

      # Flush the temporary children to the real node
      if match
        @node = backup
        temp.children.each do |child|
          @node << child
        end
      end
    end
    match
  end

  def E
    save = @node
    @node = Expression.new(@node)
    match = check_each([:E5, :E4, :E3, :E2, :E1])
    if match
      save << @node
    end
    @node = save
    match
  end

  def E1
    T()
  end

  def E2
    T() && term(:MULT) && E()
  end

  def E3
    T() && term(:DIVD) && E()
  end

  def E4
    T() && term(:PLUS) && E()
  end

  def E5
    T() && term(:MINUS) && E()
  end

  def T
    save = @node
    @node = Structure.new(@node)
    match = check_each([:T3, :T2, :T1])
    if match
      save << @node
    end
    @node = save
    match
  end

  def T1
    term(:NUMERICAL)
  end

  def T2
    term(:IDENTIFIER)
  end

  def T3
    term(:LEFT_PAREN) && E() && term(:RIGHT_PAREN)
  end
end

class ASTNode
  attr_accessor :children, :parent

  def initialize(parent)
    @children = []
    @parent = parent
  end

  def dump

    # If we reached the program node
    if @parent == self || @parent == NIL
      puts self
    else
      @parent.dump
    end
  end

  def <<(item)
    @children << item
    item
  end

  def meta
    ""
  end

  def to_s
    string = "#: #{self.class.name}"

    if meta.length > 0
      string += " - #{meta}\n"
    else
      string += "\n"
    end

    @children.each do |child|
      lines = child.to_s.each_line.entries
      lines.each {|line|
        if line[0] == "#"
          if @children.length == 1 && child.children.length < 2
            string += line.indent(1, "└╴");
          else
            string += line.indent(1, "├╴")
          end
        else
          string += line.indent(1, "│  ")
        end
      }
    end
    string
  end
end

class Program < ASTNode
  def initialize
    super(self)
  end
end

class Expression < ASTNode
end

class Structure < ASTNode
end

class Temporary < ASTNode
end

class Terminal < ASTNode
  attr_reader :token, :value

  def initialize(token, value, parent)
    super(parent)
    @token = token
    @value = value
  end

  def meta
    "#{@token} - #{@value}"
  end
end
