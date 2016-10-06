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

  # Interfaces with the native print method
  def write(arguments, stack)
    arguments.each do |arg|
      if arg.is_a?(TString)
        print arg.value
      elsif arg.is_a?(TNumeric)
        print arg.value
      elsif arg.is_a?(TBoolean)
        print arg.value
      else
        print arg
      end
    end
    TNull.new
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

  def member_read(arguments, stack)

    # Typecheck the arguments
    target = arguments[0]
    index = arguments[1]

    unless index.is_a?(TNumeric)
      raise "Expected index to be a numeric"
    end

    case target
    when .is_a?(TArray)
      return target.value[index.value.to_i]
    when .is_a?(TString)
      return TString.new(target.value[index.value.to_i].to_s)
    else
      return TNull.new
    end
  end

  def member_write(arguments, stack)

    # Typecheck the arguments
    target = arguments[0]
    index = arguments[1]
    value = arguments[2]

    unless index.is_a?(TNumeric)
      raise "Expected index to be a numeric"
    end

    case target
    when .is_a?(TArray)
      target.value[index.value.to_i] = value
      return value
    when .is_a?(TString)
      if value.is_a?(TString)
        value = value.value
      else
        value = value.to_s
      end

      new_string = ""
      target.value.each_char.with_index.each do |char, c_index|
        if c_index != index.value.to_i
          new_string += char
        else
          new_string += value
        end
      end
      target.value = new_string
      return TString.new(value)
    else
      return TNull.new
    end
  end

  def member_insert(arguments, stack)

    # Typecheck the arguments
    target = arguments[0]
    index = arguments[1]
    value = arguments[2]

    unless index.is_a?(TNumeric)
      raise "Expected index to be a numeric"
    end

    case target
    when .is_a?(TArray)
      target.value.insert(index.value.to_i, value)
      return value
    when .is_a?(TString)
      if value.is_a?(TString)
        value = value.value
      else
        value = value.to_s
      end

      target.value = target.value.insert(index.value.to_i, value)
      return TString.new(value)
    else
      return TNull.new
    end
  end

  def member_delete(arguments, stack)

    # Typecheck the arguments
    target = arguments[0]
    index = arguments[1]

    unless index.is_a?(TNumeric)
      raise "Expected index to be a numeric"
    end

    case target
    when .is_a?(TArray)
      old_value = target.value[index.value.to_i]
      target.value.delete_at(index.value.to_i)
      return old_value
    when .is_a?(TString)
      new_string = ""
      target.value.each_char.with_index.each do |char, c_index|
        if c_index != index.value.to_i
          new_string += char
        end
      end
      return TString.new(new_string)
    else
      return TNull.new
    end
  end
end
