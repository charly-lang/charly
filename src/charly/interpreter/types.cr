module Charly

  # `BaseType` is the common class all types in charly depend on
  abstract class BaseType

    # :nodoc:
    def to_s(io)
      value_to_s(io)
    end

    abstract def value_to_s(io)
  end

  # `TNumeric` is a 64 bit floating point number
  class TNumeric < BaseType
    property value : Float64

    def initialize(value)
      @value = value.to_f64
    end

    # :nodoc:
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

    # :nodoc:
    def self.to_s(io)
      io << "Numeric"
    end
  end

  class TString < BaseType
    property value : String

    def initialize(@value)
    end

    # :nodoc:
    def value_to_s(io)
      io << @value
    end

    # :nodoc:
    def self.to_s(io)
      io << "String"
    end
  end

  class TBoolean < BaseType
    property value : Bool

    def initialize(@value)
    end

    # :nodoc:
    def value_to_s(io)
      io << @value
    end

    # :nodoc:
    def self.to_s(io)
      io << "Boolean"
    end
  end

  class TArray < BaseType
    property value : Array(BaseType)

    def initialize(@value)
    end

    # :nodoc:
    def value_to_s(io)
      io << "Array:#{@value.size}"
    end

    # :nodoc:
    def self.to_s(io)
      io << "Array"
    end
  end

  class TNull < BaseType
    def initialize
    end

    # :nodoc:
    def value_to_s(io)
      io << "null"
    end

    # :nodoc:
    def self.to_s(io)
      io << "Null"
    end
  end
end
