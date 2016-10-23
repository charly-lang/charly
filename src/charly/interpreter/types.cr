require "../syntax/ast.cr"
require "./stack/stack.cr"

module CharlyTypes
  include Charly::Parser::AST

  # Internal representations of the types
  alias HashKey = String
  alias RunTimeType =
    String |
    Float64 |
    Bool |
    ASTNode |
    Array(BaseType) |
    Nil

  # The base class all charly types depend on
  abstract class BaseType
    def initialize(value)
      @value = value
    end

    def to_s(io)
      string_value = MemoryIO.new
      value_to_s(string_value)
      io << string_value
    end

    abstract def value_to_s(io)
  end

  class TString < BaseType
    property value : String

    def value_to_s(io)
      io << value
    end

    def self.to_s(io)
      io << "String"
    end
  end

  class TNumeric < BaseType
    property value : Float64

    def initialize(value)
      @value = value.to_f64
    end

    def value_to_s(io)

      if @value.nan?
        io << "NAN"
        return
      end

      if value % 1 == 0
        io << value.to_i64
      else
        io << value
      end
    end

    def self.to_s(io)
      io << "Numeric"
    end
  end

  class TBoolean < BaseType
    property value : Bool

    def value_to_s(io)
      if value
        io << "true"
      else
        io << "false"
      end
    end

    def self.to_s(io)
      io << "Boolean"
    end
  end

  class TNull < BaseType
    property value : Nil

    def initialize
      super(nil)
    end

    def value_to_s(io)
      io << "null"
    end

    def self.to_s(io)
      io << "Null"
    end
  end

  class TArray < BaseType
    property value : Array(BaseType)

    def self.new_from_strings(strings : Array(String))
      values = [] of BaseType
      strings.each do |arg|
        values << TString.new(arg)
      end
      TArray.new(values)
    end

    def value_to_s(io)
      io << "["
      @value.map_with_index do |child, index|
        io << child

        if index < @value.size - 1
          io << ", "
        end
      end
      io << "]"
    end

    def self.to_s(io)
      io << "Array"
    end
  end

  class TFunc < BaseType
    property value : Bool
    property argumentlist : Array(ASTNode)
    property block : Block
    property parent_stack : Stack
    property anonymous : Bool

    def initialize(argumentlist, block, parent_stack, anonymous = false)
      @value = false
      @argumentlist = argumentlist
      @block = block
      @block.parent_stack = parent_stack
      @parent_stack = parent_stack
      @anonymous = anonymous
    end

    def value_to_s(io)
      io << "Function"
    end

    def self.to_s(io)
      io << "Function"
    end
  end

  class TClass < BaseType
    property value : Bool
    property block : Block
    property parent_stack : Stack

    def initialize(block, parent_stack)
      @value = false
      @block = block
      @block.parent_stack = parent_stack
      @parent_stack = parent_stack
    end

    def value_to_s(io)
      io << "Class"
    end

    def self.to_s(io)
      io << "Class"
    end
  end

  class TObject < BaseType
    property value : Bool
    property stack : Stack

    def initialize(stack)
      @value = false
      @stack = stack
    end

    def self.new_from_hash(hash, parent_stack : Stack)
      new_stack = Stack.new(parent_stack)
      hash.each do |key, value|
        new_stack.write(key, TString.new(value), declaration: true)
      end
      TObject.new(new_stack)
    end

    def value_to_s(io)
      io << "Object"
    end

    def self.to_s(io)
      io << "Object"
    end
  end
end
