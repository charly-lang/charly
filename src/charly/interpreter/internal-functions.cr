require "./stack.cr"
require "./types.cr"

# Defines all methods that are implemented in the interpreter directly
# This includes print, dump, rand, various math functions, etc.
module InternalFunctions
  extend self
  include CharlyTypes

  module STDOUT
    extend self

    def print(arguments, stack)
      arguments.each do |arg|
        ::STDOUT.puts arg
        ::STDOUT.flush
      end
      TNull.new
    end

    def write(arguments, stack)
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
      arguments.each do |arg|
        ::STDERR.print arg
        ::STDERR.flush
      end
      TNull.new
    end

    def write(arguments, stack)
      arguments.each do |arg|
        ::STDERR.print arg
        ::STDERR.flush
      end
      TNull.new
    end
  end

  module STDIN
    extend self

    def getc
      return TString.new(::STDIN.read_char.to_s || "")
    end

    def gets
      return TString.new(::STDIN.gets || "")
    end
  end

  # Get the length of various types
  def length(arguments, stack)
    case arg = arguments[0]
    when .is_a? TNumeric
      return arg
    when .is_a? TString
      return TNumeric.new(arg.value.size.to_f64)
    when .is_a? TArray
      return TNumeric.new(arg.value.size.to_f64)
    else
      return TNull.new
    end
  end

  # Get an array of a given size
  # First argument has to be a numeric
  # An optional second argument can be used for the default value
  # All other arguments are ignored
  def array_of_size(arguments, stack)

    # Check if there are 2 arguments
    unless arguments.size > 0
      return TNull.new
    end

    # An array filled with TNull
    if arguments.size >= 2

      # Typecheck
      count = arguments[0]
      default = arguments[1]

      if count.is_a?(TNumeric)
        return TArray.new(Array.new(count.value.to_i, default))
      else
        raise "array_of_size expected argument 1 to be of type TNumeric, got #{count.class}"
      end
    end

    return TNull.new
  end

  # Dump all values from an object into it's parent stack
  def unpack(arguments, stack)

    # Check if there is at least 1 argument
    unless arguments.size > 0
      return TNull.new
    end

    object = arguments[0]
    if object.is_a?(TObject)

      # Get the correct stack
      # We assume this is called via the unpack method and not
      # call_internal("unpack", ...)
      #
      # This means we have to go up two stacks in order to
      # be able to write to the correct one
      object.stack.not_nil!.values.each do |key, value|
        stack.parent.not_nil!.write(key, value, true)
      end
    end
    return TNull.new
  end

  # Colorize a string with a given color code
  def colorize(arguments, stack)

    # Check if there are two arguments
    unless arguments.size > 0
      return TNull.new
    end

    if arguments.size >= 2
      text = arguments[0]
      color_code = arguments[1]

      # Typecheck
      unless color_code.is_a?(TNumeric)
        raise "colorize expected second argument to be of type TNumeric"
      end

      return TString.new("\e[#{color_code.value.to_i}m#{text}\e[0m")
    end
    return TNull.new
  end
end
