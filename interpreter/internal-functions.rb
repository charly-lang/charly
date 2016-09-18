require_relative "types.rb"
require_relative "../misc/Helper.rb"

class Interpreter
  class InternalFunctions
    def self.exec_internal_function(name, arguments, stack)
      case name.value
      when "print"
        arguments.each do |arg|
          if arg.is_a? Types::NullType
            puts "NIL"
          else
            puts arg
          end
        end
        return Types::NullType.new
      when "Boolean"
        return Types::BooleanType.new(eval_bool(arguments[0].value))
      when "Number"
        return Types::NumericType.new(arguments[0].value.to_f)
      when "String"
        return Types::StringType.new(arguments[0].value.to_s)
      when "gets"
        return Types::StringType.new($stdin.gets)
      when "chomp"
        return Types::StringType.new(arguments[0].value)
      when "sleep"
        sleep(arguments[0].value)
        return Types::NullType.new
      when "variable"
        return stack[arguments[0].value]
      when "print_color"
        puts colorize(arguments[0].value, arguments[1].value)
        return Types::NullType.new
      when "length"
        case arguments[0]
        when Types::ArrayType
          Types::NumericType.new(arguments[0].value.length)
        when Types::StringType
          Types::NumericType.new(arguments[0].value.length)
        when Types::NumericType
          arguments[0]
        else

          # TODO: Better error message
          raise "Invalid type"
        end
      when "array_of_size"
        values = []
        arguments[0].value.to_i.times do |i|
          values << Types::NullType.new
        end
        return Types::ArrayType.new(values)
      when "typeof"
        return Types::StringType.new(arguments[0].class.to_s)
      end
    end
  end
end
