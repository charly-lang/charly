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
    when Boolean
      return BooleanType.new(value)
    when Array
      return ArrayType.new(value)
    when NullType
      return value
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
  end

  class FuncType < Abstract
    attr_accessor :identifier, :arguments, :block, :parent_stack

    def initialize(identifier, arguments, block, parent_stack)
      @identifier = identifier
      @arguments = arguments
      @block = block
      @parent_stack = parent_stack
    end

    # Arguments is the parameters in the order
    # the arguments were specified on initialization
    def call(args, stack)

      # Get the identities of the arguments
      idents = @arguments.map do |arg|
        arg.value
      end

      # Insert the args into the current stack,
      # under the identity listed in the arguments
      args[0, idents.length].each_with_index do |val, index|
        stack[idents[index]] = val
      end
    end
  end

  class NullType < Abstract
    def initialize
      super(nil);
    end

    def to_s
      StringType.new "NULL"
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
  end

  class ArrayType < Abstract
    def initialize(values)
      super(values);
    end

    def to_s
      "[ArrayLiteral]"
    end
  end

  class StringType < Abstract
    def +(v)
      self.value + v.to_s
    end
  end

  class BooleanType < Abstract
    class True < Abstract; end
    class False < Abstract; end

    def self.new(value)
      if value
        True.new value
      else
        False.new value
      end
    end
  end
end
