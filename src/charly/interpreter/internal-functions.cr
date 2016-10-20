require "./stack/stack.cr"
require "./types.cr"
require "./require.cr"
require "readline"

# Defines all methods that are implemented in the interpreter directly
# This includes print, dump, rand, various math functions, etc.
module InternalFunctions
  include CharlyTypes
  extend self

  # Helper macros to describe argument types and amount
  macro describe_args(types)

    # The name of the function
    %name = arguments[0]

    # Remove the functionname from the arguments
    {% if types.size > 0 %}
      arguments = arguments[1..-1]
    {% end %}

    # Check for the argument count
    unless arguments.size == {{types.size}}
      raise "#{%name} expected #{{{types.size}}} arguments, got: #{arguments.size}"
    end

    # Check argument types
    {% for type, index in types %}

      arg{{index + 1}} = arguments[{{index}}]

      unless arg{{index + 1}}.is_a?({{type}})
        raise "#{%name} expected argument #{{{index}} + 1} to be of type #{{{type}}}, got #{arguments[{{index}}].class}"
      end
    {% end %}
  end

  def require(arguments, stack, session, userfile)
    arg1 = nil
    describe_args([TString])
    filename = arg1.value

    return Charly::Interpreter::Require.include(filename, session, userfile, true)
  end

  def include(arguments, stack, session, userfile)
    arg1 = nil
    describe_args([TString])
    filename = arg1.value

    return Charly::Interpreter::Require.include(filename, session, userfile, false)
  end

  def sleep(arguments, stack)
    arg1 = nil
    describe_args([TNumeric])

    sleep arg1.value / 1000
    return TNull.new
  end

  module STDOUT
    extend self

    def print(arguments, stack)
      arg1 = nil
      InternalFunctions.describe_args([TArray])
      arguments = arg1.value

      arguments.each do |arg|
        ::STDOUT.puts arg
        ::STDOUT.flush
      end
      TNull.new
    end

    def write(arguments, stack)
      arg1 = nil
      InternalFunctions.describe_args([TArray])
      arguments = arg1.value

      arguments.each do |arg|
        ::STDOUT.print arg
        ::STDOUT.flush
      end
      TNull.new
    end
  end

  module STDERR
    extend self

    def print(arguments, stack)
      arg1 = nil
      InternalFunctions.describe_args([TArray])
      arguments = arg1.value

      arguments.each do |arg|
        ::STDERR.print arg
        ::STDERR.flush
      end
      TNull.new
    end

    def write(arguments, stack)
      arg1 = nil
      InternalFunctions.describe_args([TArray])
      arguments = arg1.value

      arguments.each do |arg|
        ::STDERR.print arg
        ::STDERR.flush
      end
      TNull.new
    end
  end

  module STDIN
    extend self

    def getc(arguments, stack)
      char = ::STDIN.raw &.read_char
      return TString.new(char.to_s)
    end

    def gets(arguments, stack)
      arg1, arg2 = nil, nil
      InternalFunctions.describe_args([TString, TBoolean])
      prepend, append_to_history = arg1.value, arg2.value
      return TString.new(Readline.readline(prepend, append_to_history) || "")
    end
  end

  # Get the length of various types
  def length(arguments, stack)
    arg1 = nil
    describe_args([BaseType])

    case arg1
    when TNumeric
      return arg1
    when TString
      return TNumeric.new(arg1.value.size.to_f64)
    when TArray
      return TNumeric.new(arg1.value.size.to_f64)
    else
      return TNumeric.new(0)
    end
  end

  # Get an array of a given size
  # First argument has to be a numeric
  # An optional second argument can be used for the default value
  # All other arguments are ignored
  def array_of_size(arguments, stack)
    arg1, arg2 = nil, nil
    describe_args([TNumeric, BaseType])
    count, default = arg1, arg2

    return TArray.new(Array.new(arg1.value.to_i64, arg2))
  end

  # Insert a value at a given index in an array
  def array_insert(arguments, stack)
    arg1, arg2, arg3 = nil, nil, nil
    describe_args([TArray, TNumeric, BaseType])
    array, index, value = arg1, arg2, arg3

    # If the index is smaller than 0, we shift to the beginning
    # If the index is bigger than the size of the array
    # we append to the end
    if index.value <= 0
      array.value.unshift(value)
    elsif index.value >= array.value.size
      array.value << value
    else
      array.value.insert(index.value.to_i64, value)
    end

    return array
  end

  # Delete a value at a given index in an array
  def array_delete(arguments, stack)
    arg1, arg2 = nil, nil
    describe_args([TArray, TNumeric])
    array, index = arg1, arg2

    # If the index is smaller than 0, we delete the first element
    # If the index is bigger than the size of the array
    # we delete the last item
    if array.value.size == 0
      return TNull.new
    elsif index.value <= 0
      return array.value.shift
    elsif index.value >= array.value.size
      return array.value.pop
    else
      return array.value.delete_at(index.value.to_i64)
    end

    return array
  end

  # Dump all values from an object into it's parent stack
  def unpack(arguments, stack)
    arg1 = nil
    describe_args([TObject])
    object = arg1

    # Get the correct stack
    # We assume this is called via the unpack method and not
    # call_internal("unpack", ...)
    #
    # This means we have to go up two stacks in order to
    # be able to write to the correct one
    #
    # the value variable we got from values is an entry in the stack
    # we need to unpack the value from the value
    object.stack.not_nil!.values.each do |key, value|
      unless key == "self"
        stack.parent.not_nil!.write(key, value.value, declaration: true, constant: value.locked)
      end
    end

    return TNull.new
  end

  # Colorize a string with a given color code
  def colorize(arguments, stack)
    arg1, arg2 = nil, nil
    describe_args([BaseType, TNumeric])
    target, code = arg1, arg2

    return TString.new("\e[#{code.value.to_i64}m#{target}\e[0m")
  end

  # Exit the program
  # If the first argument is a TNumeric
  # It will be casted to an integer and used as the exit code
  def exit(arguments, stack)
    arg1 = nil
    describe_args([BaseType])
    code = arg1

    if code.is_a? TNumeric
      exit code.value.to_i
    else
      exit 0
    end
  end

  # Returns the type of a literal as a string
  def typeof(arguments, stack)
    arg1 = nil
    describe_args([BaseType])
    return TString.new("#{arg1.class}")
  end

  # Converts a value to a numeric
  def to_numeric(arguments, stack)
    arg1 = nil
    describe_args([TString])
    num = arg1.value.to_f64?(strict: false)

    if num.is_a? Float64
      return TNumeric.new(num)
    else
      return TNull.new
    end
  end

  # Trim a string
  def trim(arguments, stack)
    arg1 = nil
    describe_args([TString])
    return TString.new(arg1.value.strip)
  end

  # Return the codepoint of a char as an array
  def ord(arguments, stack)
    arg1 = nil
    describe_args([TString])
    if arg1.value.size > 0
      bytes = [] of BaseType
      arg1.value[0].bytes.map do |byte|
        bytes << TNumeric.new(byte)
      end
      return TArray.new(bytes)
    else
      raise "ord expected the string to have at least 1 char in it."
    end
  end

  # Several math functions, the implementation of this might change
  def math(arguments, stack)
    arg1, arg2 = nil, nil
    describe_args([TString, TNumeric])
    func_name, value = arg1, arg2

    # Generate all math bindings
    {% for name in %w(cos cosh acos acosh sin sinh asin asinh tan tanh atan atanh cbrt sqrt log) %}
      if func_name.value == "{{name.id}}"
        return TNumeric.new(Math.{{name.id}}(value.value))
      end
    {% end %}

    if func_name.value == "ceil"
      return TNumeric.new(value.value.ceil)
    end

    if func_name.value == "floor"
      return TNumeric.new(value.value.floor)
    end

    raise "Unknown math function #{func_name.value}"
  end

  def eval(arguments, stack, session)
    arg1, arg2 = nil, nil
    describe_args([TString, TObject])
    source, context = arg1, arg2

    # Isolate the context
    context_stack = context.stack.dup
    context_stack.parent = session.prelude
    context = TObject.new(context_stack)

    # Create the interpreter fascade
    interpreter = InterpreterFascade.new(session)

    # Catch exceptions
    begin
      result = interpreter.execute_file(EvalFile.new(source.value), context.stack)
      return result
    rescue e
      puts e
      return TNull.new
    end
  end

  # Return a given value from an object
  def getvalue(arguments, stack)
    arg1, arg2 = nil, nil
    describe_args([TObject, TString])
    object, prop = arg1, arg2

    if object.stack.contains prop.value
      return object.stack.get(prop.value)
    end

    TNull.new
  end

  # Set a given value on an object
  def setvalue(arguments, stack)
    arg1, arg2, arg3 = nil, nil, nil
    describe_args([TObject, TString, BaseType])
    object, prop, value = arg1, arg2, arg3
    object.stack.write(prop.value, value, declaration: true, check_parent: false)
    return value
  end
end
