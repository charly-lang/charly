# Sorry for this monstrosity
class Float
  old_to_s = instance_method(:to_s)
  define_method(:to_s) do
    if (self % 1) == 0
      self.to_i.to_s
    else
      old_to_s.bind(self).()
    end
  end
end

# TODO: Implement real typing rules
# currently i'm just "faking" it
module Types
  def self.new(value)
    case value
    when Numeric
      return NumericType.new(value)
    when String
      return StringType.new(value)
    when TrueClass, FalseClass
      return BooleanType.new(value)
    when Array
      return ArrayType.new(value)
    when NilClass
      return NullType.new
    else
      return StringType.new(value.to_s)
    end
  end

  class Abstract
    attr_accessor :value

    def initialize(value = nil)
      @value = value
    end

    # Overwrite operators
    def +(v); self.value + Abstract.extract_value(v) end
    def -(v); self.value - Abstract.extract_value(v) end
    def *(v); self.value * Abstract.extract_value(v) end
    def /(v); self.value / Abstract.extract_value(v) end
    def %(v); self.value % Abstract.extract_value(v) end
    def **(v); self.value ** Abstract.extract_value(v) end
    def >(v); self.value > Abstract.extract_value(v) end
    def <(v); self.value < Abstract.extract_value(v) end
    def <=(v); self.value <= Abstract.extract_value(v) end
    def >=(v); self.value >= Abstract.extract_value(v) end
    def ==(v); self.value == Abstract.extract_value(v) end
    def !=(v); self.value != Abstract.extract_value(v) end

    # Extract the primitive ruby value from a type
    def self.extract_value(v)
      if v.kind_of? Abstract
        v.value
      else
        v
      end
    end

    def to_s
      value.to_s
    end

    def is(*types)
      match = false
      types.each do |type|
        if !match
          match = self.kind_of? type
        end
      end
      match
    end
  end

  class FuncType < Abstract
    attr_accessor :identifier, :argumentlist, :block, :parent_stack

    def initialize(identifier, argumentlist, block, parent_stack)
      @identifier = identifier
      @argumentlist = argumentlist
      @block = block
      @parent_stack = parent_stack

      # Connect the block to the right parent_stack
      @block.parent_stack = parent_stack
    end

    def to_s
      if @identifier
        "Function:#{@identifier.value}"
      else
        "Function:[anonymous]"
      end
    end

    def self.to_s
      "Function"
    end
  end

  class ClassType < Abstract
    attr_accessor :identifier, :constructor, :block, :parent_stack

    def initialize(identifier, constructor, block, parent_stack)
      @identifier = identifier
      @constructor = constructor
      @block = block
      @parent_stack = parent_stack

      # Connect the block to the right parent_stack
      @block.parent_stack = parent_stack
    end

    def to_s
      "Class:#{@identifier.value}"
    end

    def self.to_s
      "Class"
    end
  end

  class ObjectType < Abstract
    attr_accessor :class_type, :stack

    def initialize(class_type, stack)
      @class_type = class_type
      @stack = stack
    end

    def to_s
      "[Object:#{class_type.identifier.value}]"
    end

    def self.to_s
      "Object"
    end
  end

  class NullType < Abstract
    def initialize
      super(nil);
    end

    def to_s
      "NULL"
    end

    def self.to_s
      "Null"
    end
  end

  class NumericType < Abstract
    def +(v)
      if v.is_a? StringType
        "#{self.value}#{v}"
      else
        super
      end
    end

    def self.to_s
      "Numeric"
    end
  end

  class ArrayType < Abstract
    def initialize(values)
      super(values);
    end

    def to_s
      @value.map { |value|
        value.to_s
      }.join("\n")
    end

    def self.to_s
      "Array"
    end
  end

  class StringType < Abstract
    def +(v)
      self.value + v.to_s
    end

    def self.to_s
      "String"
    end
  end

  class BooleanType < Abstract
    class True < Abstract
      def self.to_s
        "Bool"
      end
    end
    class False < Abstract
      def self.to_s
        "Bool"
      end
    end

    def self.new(value)
      if value
        True.new value
      else
        False.new value
      end
    end
  end
end
