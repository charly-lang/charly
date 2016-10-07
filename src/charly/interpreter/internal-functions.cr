require "./stack.cr"
require "./types.cr"

# Defines all methods that are implemented in the interpreter directly
# This includes print, dump, rand, various math functions, etc.
module InternalFunctions
  extend self
  include CharlyTypes

  # Interfaces with the crystal-native puts method
  def print(arguments, stack)
    arguments.each do |arg|
      if arg.is_a?(TString)
        puts arg.value
      elsif arg.is_a?(TNumeric)
        puts arg.value
      elsif arg.is_a?(TBoolean)
        puts arg.value
      else
        puts arg
      end
    end
    TNull.new
  end

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
end
