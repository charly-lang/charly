require "pathname"
require_relative "types.rb"
require_relative "../misc/Helper.rb"

class Interpreter
  class InternalFunctions
    def self.exec_internal_function(name, arguments, stack, node)
      case name.value
      when "new"

        # Unpack the constructor arguments
        arguments[1] = arguments[1].value

        return Executor.exec_object_instantiation(arguments[0], arguments[1], stack);
      when "print"
        arguments.each do |arg|
          puts arg
          STDOUT.flush
        end
        return Types::NullType.new
      when "dump"
        arguments.each do |arg|
          print arg
          STDOUT.flush
        end
      when "Boolean"
        return Types::BooleanType.new(eval_bool(arguments[0].value))
      when "Number"
        return Types::NumericType.new(arguments[0].value.to_f)
      when "String"
        return Types::StringType.new(arguments[0].value.to_s)
      when "gets"
        return Types::StringType.new($stdin.gets)
      when "chomp"
        return Types::StringType.new(arguments[0].value.chomp)
      when "sleep"
        sleep(arguments[0].value)
        return Types::NullType.new
      when "colorize"
        return Types::StringType.new(colorize(arguments[0].value, arguments[1].value))
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
      when "rand"
        return Types::NumericType.new(rand)
      when "require"

        # Construct the absolute path to the parent file
        # The parent file is the one that is including the file
        full_path = stack.top_node.program.file.fulldirectorypath
        full_path = File.join full_path, arguments[0].value
        if Pathname.new(full_path).directory?
          full_path = File.join full_path, "main.charly"
        end

        # Check if the file wasn't included already
        if !stack.session.has_file(full_path)
          return self.exec_internal_function(Types::StringType.new("load"), arguments, stack, node)
        end

        # If the file was already run before,
        # return the value returned by that file
        return stack.session.return_value_of_file(full_path)
      when "load"

        # Construct the absolute path to the parent file
        # The parent file is the one that is including the file
        full_path = stack.top_node.program.file.fulldirectorypath
        full_path = File.join full_path, arguments[0].value
        if Pathname.new(full_path).directory?
          full_path = File.join full_path, "main.charly"
        end

        # Check if the file exists
        if !Pathname.new(full_path).file? && !Pathname.new(full_path).directory?
          dlog "Failed to import dependency #{yellow(full_path)}"
          raise "Failed to import dependency #{yellow(full_path)}"
        end

        # Execute the program found in the file in the global stack
        # add a reference to the return value to the session
        return_value = InterpreterFascade.execute_files([full_path], stack.top_node)
        stack.session.add_return_value(full_path, return_value)
        return return_value
      when "dump_ast"
        puts arguments[0].to_s(arguments[1].value)
        return Types::NullType.new
      when "eval"

        # Execute and return the input
        return InterpreterFascade.execute_eval([arguments[0].value], stack)
      when "time_ms"
        return Types::NumericType.new(Time.new.to_ms)
      end
    end
  end
end
