require_relative "../misc/Helper.rb"

# A single stack, containing a pointer to it's parent stack
class Stack
  attr_accessor :parent, :values, :program, :session, :locked

  def initialize(parent)
    @parent = parent
    @values = {}
    @program = nil
    @session = nil
    @locked = false
  end

  def clear
    @values = {}
  end

  def depth(n = 0)
    if @parent
      return @parent.depth(n + 1)
    end
    return n
  end

  def top_node
    if @parent
      return @parent.top_node
    end
    return self
  end

  def session
    if @parent
      return @parent.session
    end
    return @session
  end

  # Lock the stack
  def lock
    @locked = true
  end

  # Unlock the stack
  def unlock
    @locked = false
  end

  def write(key, value, declaration = false, check_parent = true)

    # Check if this is a declaration
    if declaration

      # Check if the stack is locked
      if @locked
        raise "Could not write to variable '#{key}', stack is locked!"
      else
        @values[key] = value
        return value
      end
    end

    # Check if the current stack contains the key
    if contains key
      @values[key] = value
      return value
    elsif check_parent && @parent != nil
      return @parent.write(key, value, false, true)
    end
  end

  # Get a key from the stack
  # If the key doesn't exist, check the parent stack
  # unless *check_parent* is passed
  def get(key, check_parent = true)
    if contains key
      return @values[key]
    elsif check_parent && @parent != nil
      return @parent.get(key)
    else
      raise "Variable '#{k}' is not defined!"
    end
  end

  # Check if the current stack contains a value
  def contains(key)
    return @values.key? key
  end

  # Check if the current stack, or any of it's parents stack
  # contain a given key
  def defined(key)
    if contains(key)
      return true
    elsif @parent != nil
      return @parent.defined(key)
    else
      return false
    end
  end
end
